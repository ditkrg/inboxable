class CreateInboxableInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :inboxes do |t|
      t.string :route_name,   null: false, default: '', index: true
      t.string :postman_name, null: false, default: ''
      t.text :payload, null: true

      t.string :event_id, null: false, default: '', index: { unique: true }
      t.integer :status, null: false, default: 0

      t.integer  :attempts, null: false, default: 0
      t.datetime :last_attempted_at, null: true

      t.string :processor_class_name, null: false, default: ''
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
