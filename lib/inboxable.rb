# frozen_string_literal: true

require_relative 'inboxable/version'
require_relative 'inboxable/configuration'
require_relative 'inboxable/polling_receiver_worker'

module Inboxable
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      @configuration ||= Configuration.new
      yield(@configuration) if block_given?
    end
  end
end
