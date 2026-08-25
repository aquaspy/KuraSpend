class SpendImporter
  CAP = 500

  def self.call(user, io)
    payload = JSON.parse(read(io))
    raise ArgumentError, "not an object" unless payload.is_a?(Hash)
    raise ArgumentError, "not a KuraSpend export" unless payload["app"] == "KuraSpend" || has_spend_rows?(payload)

    count = 0
    Array(payload["subscriptions"]).first(CAP).each do |row|
      next unless row.is_a?(Hash)
      record = user.subscriptions.new(subscription_attrs(row))
      count += 1 if record.save
    end
    payment_rows = Array(payload["payment_days"])
    payment_rows = Array(payload["bills"]) if payment_rows.empty?
    payment_rows.first(CAP).each do |row|
      next unless row.is_a?(Hash)
      record = user.payment_days.new(payment_day_attrs(row))
      count += 1 if record.save
    end
    Array(payload["expenses"]).first(CAP).each do |row|
      next unless row.is_a?(Hash)
      record = user.expenses.new(expense_attrs(row))
      count += 1 if record.save
    end
    count
  end

  def self.has_spend_rows?(payload)
    %w[subscriptions payment_days bills expenses].any? { |key| Array(payload[key]).any? }
  end
  private_class_method :has_spend_rows?

  def self.read(io)
    return io if io.is_a?(String)
    io.rewind if io.respond_to?(:rewind)
    io.read
  end
  private_class_method :read

  def self.truthy?(value)
    !%w[0 false no off].include?(value.to_s.strip.downcase) && value != false
  end
  private_class_method :truthy?

  def self.subscription_attrs(row)
    {
      title: row["title"],
      amount_cents: row["amount_cents"],
      currency: row["currency"],
      interval: row["interval"],
      due_day: row["due_day"],
      billing_month: row["billing_month"],
      active: row.key?("active") ? truthy?(row["active"]) : true,
      notes: row["notes"].to_s
    }
  end
  private_class_method :subscription_attrs

  def self.payment_day_attrs(row)
    {
      title: row["title"],
      due_day: row["due_day"].presence || parsed_due_day(row["due_on"]),
      active: row.key?("active") ? truthy?(row["active"]) : true,
      notes: row["notes"].to_s
    }
  end
  private_class_method :payment_day_attrs

  def self.parsed_due_day(value)
    Date.parse(value.to_s).day if value.present?
  rescue Date::Error, TypeError, ArgumentError
    nil
  end
  private_class_method :parsed_due_day

  def self.expense_attrs(row)
    {
      title: row["title"],
      amount_cents: row["amount_cents"],
      currency: row["currency"],
      spent_on: row["spent_on"],
      category: row["category"].to_s,
      notes: row["notes"].to_s
    }
  end
  private_class_method :expense_attrs
end
