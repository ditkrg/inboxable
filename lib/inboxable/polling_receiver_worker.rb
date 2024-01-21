module Inboxable
  class PollingReceiverWorker
    include Sidekiq::Job

    def perform
      perform_activerecord
    end

    def perform_activerecord
      Inbox.pending.where(last_attempted_at: [..Time.zone.now, nil]).find_in_batches(batch_size: ENV.fetch('INBOXABLE__BATCH_SIZE', 100).to_i).each do |batch|
        batch.each do |inbox|
          inbox.processor_class_name.constantize.perform_async(inbox.id)
          inbox.update(last_attempted_at: 1.minute.from_now, status: :processing, allow_publish: false)
        end
      end
    end
  end
end
