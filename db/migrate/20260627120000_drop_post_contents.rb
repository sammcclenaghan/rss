# frozen_string_literal: true

class DropPostContents < ActiveRecord::Migration[8.1]
  def change
    drop_table :post_contents do |t|
      t.integer :post_id, null: false
      t.text :body, null: false, default: ''
      t.string :source, limit: 20, null: false, default: ''
      t.integer :word_count, null: false, default: 0
      t.timestamps
      t.index :post_id, unique: true
    end

    # The foreign key is dropped with the table; re-added on rollback.
    reversible do |dir|
      dir.down { add_foreign_key :post_contents, :posts, on_delete: :cascade }
    end
  end
end
