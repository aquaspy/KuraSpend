class ReplaceBillsWithPaymentDays < ActiveRecord::Migration[8.1]
  def up
    create_table :payment_days do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :due_day, null: false
      t.boolean :active, null: false, default: true
      t.text :notes, null: false, default: ""
      t.timestamps
    end
    add_index :payment_days, [ :user_id, :due_day ]

    if table_exists?(:bills)
      execute <<~SQL
        INSERT INTO payment_days (user_id, title, due_day, active, notes, created_at, updated_at)
        SELECT user_id, title, due_day, active, notes, created_at, updated_at
        FROM bills
      SQL
    end

    drop_table :bill_months, if_exists: true
    drop_table :bills, if_exists: true
  end

  def down
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

    create_table :bill_months do |t|
      t.references :bill, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :amount_cents
      t.boolean :paid, null: false, default: false
      t.timestamps
    end
    add_index :bill_months, [ :bill_id, :year, :month ], unique: true

    drop_table :payment_days
  end
end
