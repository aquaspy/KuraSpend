module HasMoney
  extend ActiveSupport::Concern

  included do
    validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
    validates :currency, inclusion: { in: Money::CURRENCIES }
    before_validation :normalize_money
  end

  def amount
    Money.input_amount(amount_cents)
  end

  def amount=(value)
    self.amount_cents = Money.parse_cents(value)
  end

  private
    def normalize_money
      self.currency = currency.to_s.upcase.presence || "BRL"
    end
end
