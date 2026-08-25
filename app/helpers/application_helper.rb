module ApplicationHelper
  def signup_enabled?
    Kura.signup_enabled?
  end

  def month_nav_path(date)
    month_path(year: date.year, month: date.month)
  end

  def money(cents, currency = current_user.home_currency)
    Money.format(cents, currency: currency)
  end

  def amount_input(cents)
    Money.input_amount(cents)
  end

  def money_pair(line)
    original = money(line.amount_cents, line.currency)
    return original if line.skipped || line.currency == current_user.home_currency

    "#{money(line.home_cents, current_user.home_currency)} · #{original}"
  end

  def currency_options
    Money::CURRENCIES.map { |code| [ t("currencies.#{code}"), code ] }
  end

  def category_options
    [ [ t("app.category_none"), "" ] ] + Expense::CATEGORIES.map { |key| [ t("categories.#{key}"), key ] }
  end
end
