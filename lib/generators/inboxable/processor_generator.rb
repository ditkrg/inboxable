module Inboxable
  class ProcessorGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :processor_name, type: :string, default: 'Processor', desc: 'Class name for the processor'

    def initialize(*args)
      super(*args)

      @processor_name = options[:processor_name].classify.to_s
      @processor_name != 'Processor' || raise('Processor name is required')
    end

    def copy_initializer
      target_path = "app/sidekiq/processors/#{@processor_name.underscore.downcase}.rb"

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Processor already exists')
      else

        create_file(target_path, <<-FILE
module Processors
  class #{@processor_name}
    include Sidekiq::Job

    def resource_model
      raise NotImplementedError # e.g. User
    end

    def perform(id)
      resource = Inbox.find(id)

      return if resource.processed?

      payload = JSON.parse(resource.payload)['data']

      resource_model.where(id: payload['id']).where('version < :version', version: payload['version']).update_all(
        version: payload['version']
        # TODO: add other attributes
      )
    end
  end
end
              FILE
        )
      end
    end
  end
end
