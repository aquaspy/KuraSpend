class MonthsController < ApplicationController
  def show
    @summary = MonthSummary.new(user: current_user, year: month_date.year, month: month_date.month)
  end

  def export
    payload = {
      "app" => "KuraSpend",
      "exported_at" => Time.current.iso8601,
      "user" => {
        "home_currency" => current_user.home_currency,
        "monthly_income_cents" => current_user.monthly_income_cents,
        "income_currency" => current_user.income_currency,
        "fx" => current_user.fx_hash
      },
      "subscriptions" => current_user.subscriptions.order(:title, :id).map(&:as_export),
      "payment_days" => current_user.payment_days.order(:due_day, :id).map(&:as_export),
      "expenses" => current_user.expenses.order(:spent_on, :id).map(&:as_export)
    }
    send_data JSON.pretty_generate(payload),
      filename: "kuraspend-#{Date.current}.json",
      type: "application/json"
  end

  def import
    file = params[:file]
    raise ArgumentError, "missing file" unless file.respond_to?(:read)
    count = SpendImporter.call(current_user, file)
    redirect_to root_path, notice: t("app.import_done", count: count)
  rescue ArgumentError, JSON::ParserError, TypeError, NoMethodError => e
    Rails.logger.warn("[import] #{e.class}: #{e.message}")
    redirect_to root_path, alert: t("app.import_invalid")
  end

  private
    def month_date
      year = params[:year].presence&.to_i
      month = params[:month].presence&.to_i
      Date.new(year, month, 1)
    rescue Date::Error, TypeError, ArgumentError
      Date.current.beginning_of_month
    end
end
