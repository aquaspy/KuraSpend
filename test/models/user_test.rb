require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and requires a long enough password" do
    user = User.create!(email: "  Ada@Example.com ", password: "secret-password")
    assert_equal "ada@example.com", user.email
    assert_equal "BRL", user.home_currency
    assert_equal 0, user.monthly_income_cents
    assert_raises(ActiveRecord::RecordInvalid) do
      User.create!(email: "other@example.com", password: "short")
    end
  end

  test "fx hash ignores home currency and blank rates" do
    user = User.create!(email: "lin@example.com", password: "secret-password", home_currency: "BRL")
    user.fx_hash = { "USD" => "5.45", "EUR" => " ", "BRL" => "1", "GBP" => "7" }
    user.save!
    assert_equal({ "USD" => "5.45" }, user.reload.fx_hash)
    user.monthly_income = "10.000,00"
    user.save!
    assert_equal 1_000_000, user.monthly_income_cents
  end
end
