class Inbox < ApplicationRecord
  attribute :allow_processing, :boolean, default: true

  # Callbacks
  after_commit :process, if: :allow_processing?

  # Scopes and Enums
  enum status: { pending: 0, processed: 1, failed: 2 }

  def increment_attempt
    self.attempts = attempts + 1
    self.last_attempted_at = Time.zone.now
  end

  def process
    processor_class_name.constantize.perform_async(id)
  end

  def check_threshold_reach
    return if attempts < ENV.fetch('INBOXABLE__MAX_ATTEMPTS', 3)&.to_i

    self.retry_at = Time.zone.now + ENV.fetch('INBOXABLE__RETRY_DELAY_IN_SECONDS', 5)&.to_i&.seconds
    self.status = :failed
    self.allow_processing = false
  end

  def check_publishing
    self.allow_processing = false if processed?
  end
end
