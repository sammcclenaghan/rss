# frozen_string_literal: true

class CreatePostContents < ActiveRecord::Migration[8.1]
  def change
    create_table :post_contents do |t|
      t.integer :post_id, null: false
      t.text :body, null: false, default: ''
      t.string :source, limit: 20, null: false, default: ''
      t.integer :word_count, null: false, default: 0
      t.timestamps
    end

    add_index :post_contents, :post_id, unique: true
    add_foreign_key :post_contents, :posts, on_delete: :cascade
  end
end
