class CreateBills < ActiveRecord::Migration[8.1]
  def change
    create_table :bills do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.integer :due_day, null: false
      t.boolean :active, null: false, default: true
      t.text :notes, null: false, default: ""
      t.timestamps
    end
    add_index :bills, [ :user_id, :due_day ]
  end
end
