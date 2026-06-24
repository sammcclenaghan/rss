class CreateReadPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :read_posts do |t|
      t.references :post, null: false,
                   foreign_key: { on_delete: :cascade },
                   index: { unique: true }

      t.timestamps
    end
  end
end
