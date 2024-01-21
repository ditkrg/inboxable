module Inboxable
  class Configuration
    ALLOWED_ORMS = %i[activerecord mongoid].freeze

    attr_accessor :orm

    def initialize
      raise Error, 'Sidekiq is not available. Unfortunately, sidekiq must be available for Inboxable to work' unless Object.const_defined?('Sidekiq')
      raise Error, 'Inboxable Gem uses the sidekiq-cron Gem. Make sure you add it to your project' unless Object.const_defined?('Sidekiq::Cron')
      raise Error, 'Inboxable Gem only supports Rails but you application does not seem to be a Rails app' unless Object.const_defined?('Rails')
      raise Error, 'Inboxable Gem only support Rails version 7 and newer' if Rails::VERSION::MAJOR < 7

      Sidekiq::Options[:cron_poll_interval] = ENV.fetch('INBOXABLE__CRON_POLL_INTERVAL', 5).to_i
      Sidekiq::Cron::Job.create(name: 'InboxablePollingReceiver', cron: ENV.fetch('INBOXABLE__CRON', '*/5 * * * * *'), class: 'Inboxable::PollingReceiverWorker')
    end

    def orm=(orm)
      raise ArgumentError, "ORM must be one of #{ALLOWED_ORMS}" unless ALLOWED_ORMS.include?(orm)

      @orm = orm
    end

    def orm
      @orm || :activerecord
    end
  end
end
