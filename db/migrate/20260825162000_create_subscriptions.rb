class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.string :interval, null: false, default: "monthly"
      t.integer :due_day
      t.integer :billing_month
      t.boolean :active, null: false, default: true
      t.text :notes, null: false, default: ""
      t.timestamps
    end
    add_index :subscriptions, [ :user_id, :title ]
  end
end
