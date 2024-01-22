module Schemable
  class HandlerGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :handler_name, type: :string, default: 'Handler', desc: 'Name of the handler class'
    class_option :api_namespace, type: :string, default: 'ApiNamespace', desc: 'Name of the api namespace of the handler class'
    attr_reader :nested_namespace?

    def initialize(*args)
      super(*args)

      @handler_name = options[:handler_name]
      @handler_name != 'Handler' || raise('Handler name is required')

      @api_namespace = options[:api_namespace].classify.to_s
      @api_namespace != 'ApiNamespace' || raise('Api namespace is required')

      @nested_namespace = @api_namespace.include?('::')
    end

    def determine_target_path
      base_path = 'app/services/event_handlers'

      if @nested_namespace
        @api_namespace.split('::').each do |namespace|
          base_path = "#{base_path}/#{namespace.underscore.downcase.pularize}"
        end

        "#{base_path}/#{@handler_name}"
      else
        "base_path/#{@api_namespace.underscore.downcase.pularize}/#{@handler_name.underscore.downcase.pularize}.rb"
      end
    end

    def copy_initializer
      target_path = determine_target_path

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Handler definition already exists')
      else

        create_file(target_path, <<-FILE
              module EventHandlers::#{@api_namespace}
                class #{@handler_name}
                  def processor_class_name
                    raise NotImplementedError # 'Processors::ExampleUpdateJob'
                  end

                  def self.handle!(_channel, delivery_info, properties, payload)
                    raise ::RabbitCarrots::EventHandlers::Errrors::NackMessage if payload.blank?

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
