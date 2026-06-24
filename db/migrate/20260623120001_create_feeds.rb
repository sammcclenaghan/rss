class CreateFeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :feeds do |t|
      t.string :url, limit: 250, null: false
      t.bigint :last_fetched_at, default: 0, null: false
      t.bigint :last_accessed_at, default: 0, null: false

      t.timestamps

      t.index :url, unique: true
      t.index :last_fetched_at
      t.index :last_accessed_at
    end
  end
end
