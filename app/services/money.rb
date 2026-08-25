module Money
  CURRENCIES = %w[BRL USD EUR].freeze
  SYMBOLS = { "BRL" => "R$", "USD" => "$", "EUR" => "€" }.freeze

  class MissingRate < StandardError
    attr_reader :currency

    def initialize(currency)
      @currency = currency.to_s.upcase
      super(@currency)
    end
  end

  module_function

  def to_home_cents(amount_cents, from:, home:, rates:)
    from = from.to_s.upcase
    home = home.to_s.upcase
    cents = amount_cents.to_i
    return cents if from == home

    rate = rates.is_a?(Hash) ? rates[from] || rates[from.to_sym] : nil
    raise MissingRate, from if rate.blank?

    (BigDecimal(cents.to_s) * BigDecimal(rate.to_s)).round.to_i
  end

  def parse_cents(value)
    str = value.to_s.strip
    return if str.blank?

    negative = str.start_with?("-")
    cleaned = str.gsub(/[^\d,.]/, "")
    return if cleaned.blank?

    normalized = normalize_decimal(cleaned)
    cents = (BigDecimal(normalized) * 100).round.to_i
    negative ? -cents : cents
  rescue ArgumentError
    nil
  end

  def format(cents, currency: "BRL")
    currency = currency.to_s.upcase
    symbol = SYMBOLS[currency] || "#{currency} "
    number = format_number(cents.to_i)
    return "#{number} #{currency}" unless SYMBOLS[currency]

    if I18n.locale.to_s.start_with?("pt")
      "#{symbol} #{number}"
    else
      "#{symbol}#{number}"
    end
  end

  def input_amount(cents)
    return "" if cents.nil?

    sign = cents.to_i.negative? ? "-" : ""
    abs = cents.to_i.abs
    whole = abs / 100
    frac = (abs % 100).to_s.rjust(2, "0")
    sep = I18n.locale.to_s.start_with?("pt") ? "," : "."
    "#{sign}#{whole}#{sep}#{frac}"
  end

  def format_number(cents)
    sign = cents.negative? ? "-" : ""
    abs = cents.abs
    whole = abs / 100
    frac = (abs % 100).to_s.rjust(2, "0")
    if I18n.locale.to_s.start_with?("pt")
      "#{sign}#{delimit(whole, ".")},#{frac}"
    else
      "#{sign}#{delimit(whole, ",")}.#{frac}"
    end
  end

  def delimit(whole, separator)
    whole.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1#{separator}").reverse
  end

  def normalize_decimal(cleaned)
    comma = cleaned.rindex(",")
    dot = cleaned.rindex(".")

    if comma && dot
      if comma > dot
        cleaned.delete(".").tr(",", ".")
      else
        cleaned.delete(",")
      end
    elsif comma
      split_last_separator(cleaned, ",")
    elsif dot
      split_last_separator(cleaned, ".")
    else
      cleaned
    end
  end

  def split_last_separator(cleaned, separator)
    whole, frac = cleaned.split(separator, 2)
    if frac && frac.length <= 2 && !frac.include?(separator)
      "#{whole.delete(separator == ',' ? '.' : ',')}.#{frac}"
    else
      cleaned.delete(separator)
    end
  end
end
