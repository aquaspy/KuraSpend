class AddMoneyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :home_currency, :string, null: false, default: "BRL"
    add_column :users, :monthly_income_cents, :integer, null: false, default: 0
    add_column :users, :income_currency, :string, null: false, default: "BRL"
    add_column :users, :fx, :text, null: false, default: "{}"
  end
end
