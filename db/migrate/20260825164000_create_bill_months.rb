class CreateBillMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :bill_months do |t|
      t.references :bill, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :amount_cents
      t.boolean :paid, null: false, default: false
      t.timestamps
    end
    add_index :bill_months, [ :bill_id, :year, :month ], unique: true
  end
end
