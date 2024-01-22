module Schemable
  class ProcessorTemplateGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :processor_template_name, type: :string, default: 'ProcessorTemplate', desc: 'Name of the processor template class'

    def initialize(*args)
      super(*args)

      @processor_template_name = options[:processor_template_name].classify.to_s
      @processor_template_name != 'ProcessorTemplate' || raise('Processor template name is required')
    end

    def copy_initializer
      target_path = "app/sidekiq/processors/#{@processor_template_name.underscore.downcase.singularize}.rb"

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Processor already exists')
      else

        create_file(target_path, <<-FILE
              module Processors
                class #{@processor_template_name}
                  include Sidekiq::Job

                  def resource_model
                    raise NotImplementedError # e.g. User
                  end

                  def perform(id)
                    resource = Inbox.find(id)

                    return if resource.processed?

                    payload = JSON.parse(resource.payload)

                    payload = payload['data']

                    # rubocop:disable Rails/SkipsModelValidations
                    resource_model.where(id: payload['id']).where('version < :version', version: payload['version']).update_all(
                      version: payload['version']
                      # TODO: add other attributes
                    )
                    # rubocop:enable Rails/SkipsModelValidations
                  end
                end
              end
              FILE
        )
      end
    end
  end
end
