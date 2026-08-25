require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "ada@example.com", password: "secret-password")
  end

  test "parses amount and requires a title" do
    expense = @user.expenses.create!(title: "Coffee", amount: "12,50", currency: "BRL", spent_on: Date.new(2026, 8, 25))
    assert_equal 1250, expense.amount_cents
    assert_raises(ActiveRecord::RecordInvalid) do
      @user.expenses.create!(title: "", amount: "1", spent_on: Date.current)
    end
  end
end
