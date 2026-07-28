class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :complete_by, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
