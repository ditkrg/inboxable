module Inboxable
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../../templates', __dir__)
    class_option :orm, type: :string, default: 'activerecord'

    def initialize
      super

      @orm = options[:orm] || 'activerecord'
      %w[activerecord mongoid].include?(@orm) || raise(ArgumentError, 'Invalid ORM. Only ActiveRecord and Mongoid are supported.')
    end

    # Copy initializer into user app
    def copy_initializer
      copy_file('activerecord_initializer.rb', 'config/initializers/z_inboxable.rb') if @orm == 'activerecord'
      copy_file('mongoid_initializer.rb', 'config/initializers/z_inboxable.rb') if @orm == 'mongoid'
    end

    # Copy user information (model & Migrations) into user app
    def create_user_model
      target_path = 'app/models/inbox.rb'

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Model inbox already exists')
      else
        template('activerecrod_inbox.rb', target_path) if @orm == 'activerecord'
        template('mongoid_inbox.rb', target_path) if @orm == 'mongoid'
      end
    end

    # Copy migrations
    def copy_migrations
      return if @orm == 'mongoid'

      if self.class.migration_exists?('db/migrate', 'create_inboxable_inboxes')
        say_status('skipped', 'Migration create_inboxable_inboxes already exists')
      else
        migration_template('create_inboxable_inboxes.rb', 'db/migrate/create_inboxable_inboxes.rb')
      end
    end

    # Use to assign migration time otherwise generator will error
    def self.next_migration_number(_dir)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end
  end
end
