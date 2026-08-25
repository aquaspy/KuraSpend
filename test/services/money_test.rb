require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "same currency is identity" do
    assert_equal 1234, Money.to_home_cents(1234, from: "BRL", home: "BRL", rates: {})
  end

  test "multiplies cents by the unit rate" do
    assert_equal 5450, Money.to_home_cents(1000, from: "USD", home: "BRL", rates: { "USD" => "5.45" })
  end

  test "missing rate raises" do
    error = assert_raises(Money::MissingRate) do
      Money.to_home_cents(100, from: "EUR", home: "BRL", rates: {})
    end
    assert_equal "EUR", error.currency
  end

  test "parses locale amounts" do
    assert_equal 1250, Money.parse_cents("12,50")
    assert_equal 1250, Money.parse_cents("12.50")
    assert_equal 123456, Money.parse_cents("1.234,56")
    assert_equal 123456, Money.parse_cents("1,234.56")
    assert_equal 1200, Money.parse_cents("12")
    assert_nil Money.parse_cents("")
    assert_equal(-500, Money.parse_cents("-5,00"))
  end

  test "formats without a stray space" do
    I18n.with_locale(:pt) do
      assert_equal "R$ 1.234,56", Money.format(123_456, currency: "BRL")
    end
    I18n.with_locale(:en) do
      assert_equal "$1,234.56", Money.format(123_456, currency: "USD")
    end
  end
end
