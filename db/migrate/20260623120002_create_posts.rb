# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :feed, null: false, foreign_key: true
      t.bigint :published_at, null: false
      t.string :title, limit: 250, null: false
      t.text :description, default: '', null: false
      t.string :url, limit: 250, null: false
      t.string :guid, limit: 250, null: false
      t.string :thumbnail, default: '', null: false

      t.timestamps

      t.index :published_at
      t.index %i[feed_id guid], unique: true
    end
  end
end
