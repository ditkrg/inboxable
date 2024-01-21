module Inboxable
  class Configuration
    ALLOWED_ORMS = %i[activerecord].freeze

    attr_accessor :orm

    def initialize
      raise Error, 'Inboxable Gem only supports Rails but you application does not seem to be a Rails app' unless Object.const_defined?('Rails')
      raise Error, 'Inboxable Gem only support Rails version 7 and newer' if Rails::VERSION::MAJOR < 7

      Sidekiq::Options[:cron_poll_interval] = 5
      Sidekiq::Cron::Job.create(name: 'InboxablePollingReceiver', cron: '*/5 * * * * *', class: 'Inboxable::PollingReceiverWorker')
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
