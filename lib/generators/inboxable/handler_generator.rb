module Inboxable
  class HandlerGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :handler_name, type: :string, default: 'Handler', desc: 'Class name for the handler'
    class_option :namespace, type: :string, default: 'Namespace', desc: 'Namespace directory for the handler'
    attr_reader :nested_namespace

    def initialize(*args)
      super(*args)

      @handler_name = options[:handler_name]
      @handler_name != 'Handler' || raise('Handler name is required')

      @namespace = options[:namespace].classify.to_s
      @namespace != 'Namespace' || raise('Namespace is required')

      @nested_namespace = @namespace.include?('::')
    end

    def determine_target_path
      base_path = 'app/services/event_handlers'

      if @nested_namespace
        @namespace.split('::').each do |namespace|
          base_path = "#{base_path}/#{namespace.underscore.downcase}"
        end

        "#{base_path}/#{@handler_name}"
      else
        "#{base_path}/#{@namespace.underscore.downcase}/#{@handler_name.underscore.downcase}.rb"
      end
    end

    def copy_initializer
      target_path = determine_target_path

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Handler already exists')
      else

        create_file(target_path, <<-FILE
module EventHandlers::#{@namespace}
  class #{@handler_name.classify}
    def processor_class_name
      raise NotImplementedError # e.g. 'Processors::ExampleUpdateJob'
    end

    def self.handle!(_channel, delivery_info, properties, payload)
      raise ::RabbitCarrots::EventHandlers::Errors::NackMessage if payload.blank?

      begin
        Inbox.create!(
          route_name: delivery_info.routing_key,
          postman_name: delivery_info&.consumer&.queue&.name,
          payload:,
          event_id: JSON.parse(payload)['id'],
          status: :pending,
          processor_class_name:, # TODO: change this
          metadata: properties[:headers]
        )

      rescue ActiveRecord::RecordNotUnique
        true
      end
    end
  end
end
              FILE
        )
      end
    end
  end
end
