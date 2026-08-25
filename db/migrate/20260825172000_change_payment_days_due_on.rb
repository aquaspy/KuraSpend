class ChangePaymentDaysDueOn < ActiveRecord::Migration[8.1]
  class PaymentDay < ApplicationRecord; end

  def up
    add_column :payment_days, :due_on, :date
    PaymentDay.reset_column_information
    today = Date.current
    PaymentDay.find_each do |row|
      day = [ row.due_day, Time.days_in_month(today.month, today.year) ].min
      row.update_columns(due_on: Date.new(today.year, today.month, day))
    end
    change_column_null :payment_days, :due_on, false
    remove_index :payment_days, column: [ :user_id, :due_day ]
    remove_column :payment_days, :due_day
    add_index :payment_days, [ :user_id, :due_on ]
  end

  def down
    add_column :payment_days, :due_day, :integer
    PaymentDay.reset_column_information
    PaymentDay.find_each do |row|
      row.update_columns(due_day: row.due_on.day)
    end
    change_column_null :payment_days, :due_day, false
    remove_index :payment_days, column: [ :user_id, :due_on ]
    remove_column :payment_days, :due_on
    add_index :payment_days, [ :user_id, :due_day ]
  end
end
