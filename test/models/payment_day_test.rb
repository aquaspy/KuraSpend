require "test_helper"

class PaymentDayTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "ada@example.com", password: "secret-password")
  end

  test "clamps day 31 to the end of short months" do
    day = @user.payment_days.create!(title: "Card", due_day: 31)
    assert_equal Date.new(2026, 2, 28), day.due_on(2026, 2)
    assert_equal Date.new(2026, 8, 31), day.due_on(2026, 8)
  end
end
