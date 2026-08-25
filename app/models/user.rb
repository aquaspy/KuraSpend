class User < ApplicationRecord
  has_secure_password
  has_many :subscriptions, dependent: :destroy
  has_many :payment_days, dependent: :destroy
  has_many :expenses, dependent: :destroy

  normalizes :email, with: -> { it.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :home_currency, inclusion: { in: Money::CURRENCIES }
  validates :income_currency, inclusion: { in: Money::CURRENCIES }
  validates :monthly_income_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :fx_rates_make_sense

  def monthly_income
    Money.input_amount(monthly_income_cents)
  end

  def monthly_income=(value)
    self.monthly_income_cents = Money.parse_cents(value) || 0
  end

  def fx_hash
    raw = JSON.parse(fx.presence || "{}")
    raw.each_with_object({}) do |(key, value), acc|
      code = key.to_s.upcase
      next unless Money::CURRENCIES.include?(code)
      next if code == home_currency
      next if value.to_s.strip.blank?

      acc[code] = value.to_s.strip
    end
  rescue JSON::ParserError
    {}
  end

  def fx_hash=(incoming)
    pairs = {}
    Hash(incoming).each do |key, value|
      code = key.to_s.upcase
      next unless Money::CURRENCIES.include?(code)
      next if code == home_currency.to_s.upcase
      next if value.to_s.strip.blank?

      pairs[code] = value.to_s.strip
    end
    self.fx = pairs.to_json
  end

  def rate_for(currency)
    code = currency.to_s.upcase
    return "1" if code == home_currency

    fx_hash[code]
  end

  private
    def fx_rates_make_sense
      self.home_currency = home_currency.to_s.upcase.presence || "BRL"
      self.income_currency = income_currency.to_s.upcase.presence || home_currency
      fx_hash.each_value do |value|
        number = BigDecimal(value)
        errors.add(:fx, :invalid) if number <= 0
      rescue ArgumentError
        errors.add(:fx, :invalid)
      end
    end
end
