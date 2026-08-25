require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "ada@example.com", password: "secret-password")
  end

  test "yearly applies only in billing month" do
    sub = @user.subscriptions.create!(title: "Domain", amount: "120", currency: "BRL", interval: "yearly", billing_month: 3)
    assert sub.applies_in?(2026, 3)
    refute sub.applies_in?(2026, 8)
    monthly = @user.subscriptions.create!(title: "Netflix", amount: "50", currency: "BRL")
    assert monthly.applies_in?(2026, 1)
    assert monthly.applies_in?(2026, 8)
  end
end
