require 'sidekiq'

module Inboxable
  class PollingReceiverWorker
    include Sidekiq::Job

    def perform
      Inboxable.configuration.orm == :activerecord ? perform_activerecord : perform_mongoid
    end

    def perform_activerecord
      Inboxable.inbox_model.pending
               .find_in_batches(batch_size: ENV.fetch('INBOXABLE__BATCH_SIZE', 100).to_i)
               .each do |batch|
        batch.each do |inbox|
          inbox.processor_class_name.constantize.perform_async(inbox.id)
          inbox.update(last_attempted_at: Time.zone.now, status: :processing, allow_processing: false)
        end
      end
    end

    def perform_mongoid
      batch_size = ENV.fetch('INBOXABLE__BATCH_SIZE', 100).to_i
      Inboxable.inbox_model.pending
               .each_slice(batch_size) do |batch|
        batch.each do |inbox|
          inbox.processor_class_name.constantize.perform_async(inbox.id.to_s)
          inbox.update(last_attempted_at: Time.zone.now, status: :processing, allow_processing: false)
        end
      end
    end
  end
end
