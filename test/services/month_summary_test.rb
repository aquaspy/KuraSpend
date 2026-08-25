require "test_helper"

class MonthSummaryTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "ada@example.com",
      password: "secret-password",
      home_currency: "BRL",
      monthly_income_cents: 1_000_000,
      income_currency: "BRL",
      fx: { "USD" => "5.45" }.to_json
    )
    @today = Date.new(2026, 8, 25)
  end

  test "leftover subtracts subscriptions and expenses, not payment days" do
    @user.subscriptions.create!(title: "Netflix", amount_cents: 5_000, currency: "BRL", interval: "monthly")
    @user.subscriptions.create!(title: "Domain", amount_cents: 12_000, currency: "BRL", interval: "yearly", billing_month: 3)
    @user.subscriptions.create!(title: "Insurance", amount_cents: 20_000, currency: "BRL", interval: "yearly", billing_month: 8)
    @user.payment_days.create!(title: "Water", due_day: 10)
    @user.payment_days.create!(title: "Card", due_day: 8)
    @user.expenses.create!(title: "Coffee", amount_cents: 1_500, currency: "BRL", spent_on: Date.new(2026, 8, 12))
    @user.expenses.create!(title: "USD snack", amount_cents: 1_000, currency: "USD", spent_on: Date.new(2026, 8, 13))

    summary = MonthSummary.new(user: @user, year: 2026, month: 8, today: @today)

    assert_equal 1_000_000, summary.income_home_cents
    assert_equal 25_000, summary.subscriptions_home_cents
    assert_equal 6_950, summary.expenses_home_cents
    assert_equal 968_050, summary.leftover_cents
    assert_equal 2, summary.payment_days.size
    assert summary.payment_days.all?(&:overdue)
    assert_empty summary.missing_rate_currencies
  end

  test "yearly out of month and inactive subscriptions do not count" do
    @user.subscriptions.create!(title: "Old", amount_cents: 9_000, currency: "BRL", interval: "monthly", active: false)
    @user.subscriptions.create!(title: "Domain", amount_cents: 12_000, currency: "BRL", interval: "yearly", billing_month: 1)
    summary = MonthSummary.new(user: @user, year: 2026, month: 8, today: @today)
    assert_equal 0, summary.subscriptions_home_cents
    assert_equal 1, summary.subscription_rows.size
  end

  test "missing rates are skipped and a payment day today is flagged" do
    @user.payment_days.create!(title: "Power", due_day: 25)
    @user.expenses.create!(title: "Euro", amount_cents: 2_000, currency: "EUR", spent_on: Date.new(2026, 8, 2))
    summary = MonthSummary.new(user: @user, year: 2026, month: 8, today: @today)
    assert_equal 0, summary.expenses_home_cents
    assert_equal [ "EUR" ], summary.missing_rate_currencies
    assert summary.payment_days.first.due_today
    refute summary.payment_days.first.overdue
  end
end
