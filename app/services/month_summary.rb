class MonthSummary
  Line = Data.define(
    :id, :kind, :title, :notes, :amount_cents, :currency, :home_cents, :skipped,
    :due_day, :due_on, :overdue, :due_today, :category, :spent_on, :interval,
    :counts, :billing_month
  )

  attr_reader :user, :year, :month, :start_on, :end_on, :today

  def initialize(user:, year:, month:, today: Date.current)
    @user = user
    @year = year
    @month = month
    @start_on = Date.new(year, month, 1)
    @end_on = @start_on.end_of_month
    @today = today
    @home = user.home_currency
    @rates = user.fx_hash
  end

  def prev_month
    start_on << 1
  end

  def next_month
    start_on >> 1
  end

  def current_month?
    today.year == year && today.month == month
  end

  def income
    convert(
      id: nil,
      kind: :income,
      title: "salary",
      amount_cents: user.monthly_income_cents.to_i,
      currency: user.income_currency
    )
  end

  def subscription_rows
    user.subscriptions.active.order(:title, :id).map do |subscription|
      convert(
        id: subscription.id,
        kind: :subscription,
        title: subscription.title,
        notes: subscription.notes,
        amount_cents: subscription.amount_cents,
        currency: subscription.currency,
        due_day: subscription.due_day,
        interval: subscription.interval,
        billing_month: subscription.billing_month,
        counts: subscription.applies_in?(year, month)
      )
    end
  end

  def subscriptions
    subscription_rows.select(&:counts)
  end

  def payment_days
    user.payment_days.active.order(:due_day, :title, :id).map do |day|
      due = day.due_on(year, month)
      convert(
        id: day.id,
        kind: :payment_day,
        title: day.title,
        notes: day.notes,
        amount_cents: 0,
        currency: @home,
        due_day: day.due_day,
        due_on: due,
        overdue: current_month? && due < today,
        due_today: current_month? && due == today
      )
    end
  end

  def expenses
    user.expenses.where(spent_on: start_on..end_on).order(spent_on: :desc, id: :desc).map do |expense|
      convert(
        id: expense.id,
        kind: :expense,
        title: expense.title,
        notes: expense.notes,
        amount_cents: expense.amount_cents,
        currency: expense.currency,
        category: expense.category,
        spent_on: expense.spent_on
      )
    end
  end

  def expenses_by_day
    expenses.group_by(&:spent_on)
  end

  def income_home_cents = totaled(income)
  def subscriptions_home_cents = sum(subscriptions)
  def expenses_home_cents = sum(expenses)
  def leftover_cents = income_home_cents - subscriptions_home_cents - expenses_home_cents

  def missing_rate_currencies
    (Array(income) + subscriptions + expenses).select(&:skipped).map(&:currency).uniq
  end

  def salary_missing?
    user.monthly_income_cents.to_i.zero?
  end

  private
    def convert(id:, kind:, title:, amount_cents:, currency:, notes: "", due_day: nil, due_on: nil, overdue: false, due_today: false, category: "", spent_on: nil, interval: nil, counts: true, billing_month: nil)
      home_cents = nil
      skipped = false
      begin
        home_cents = Money.to_home_cents(amount_cents, from: currency, home: @home, rates: @rates)
      rescue Money::MissingRate
        skipped = true
      end

      Line.new(
        id:, kind:, title:, notes: notes.to_s, amount_cents:, currency:, home_cents:, skipped:,
        due_day:, due_on:, overdue:, due_today:, category: category.to_s, spent_on:, interval:,
        counts:, billing_month:
      )
    end

    def totaled(line)
      line.skipped ? 0 : line.home_cents.to_i
    end

    def sum(lines)
      lines.sum { |line| totaled(line) }
    end
end
