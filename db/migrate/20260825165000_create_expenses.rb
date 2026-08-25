class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.date :spent_on, null: false
      t.string :category, null: false, default: ""
      t.text :notes, null: false, default: ""
      t.timestamps
    end
    add_index :expenses, [ :user_id, :spent_on ]
  end
end