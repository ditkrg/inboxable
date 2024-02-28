class Inbox
  include Mongoid::Document
  include Mongoid::Timestamps
  include SimpleEnum::Mongoid

  field :route_name, type: String
  field :postman_name, type: String
  field :payload, type: String
  field :event_id, type: String
  field :attempts, type: Integer, default: 0
  field :last_attempted_at, type: Time
  field :processor_class_name, type: String
  field :metadata, type: Hash, default: {}

  # Indexes
  index({ event_id: 1 }, unique: true)

  attr_accessor :allow_processing

  as_enum :status, %i[pending processed failed processing], field: { type: String, default: 'pending' }, map: :string

  statuses.each_key do |key|
    scope key, -> { where(status_cd: key) }
  end

  validates :processor_class_name, presence: true

  after_create :process, if: proc { |resource| resource.allow_processing == true }

  def increment_attempt
    self.attempts = attempts + 1
    self.last_attempted_at = Time.zone.now
  end

  def process
    processor_class_name.constantize.perform_async(id.to_s)
  end

  def check_threshold_reach
    return if attempts < ENV.fetch('INBOXABLE__MAX_ATTEMPTS', 3)&.to_i

    self.retry_at = Time.zone.now + ENV.fetch('INBOXABLE__RETRY_DELAY_IN_SECONDS', 5)&.to_i&.seconds
    self.status = :failed
    self.allow_processing = false
  end

  def check_publishing
    self.allow_processing = false unless pending?
  end
end
