module Api
  module V1
    class MonthsController < Api::BaseController
      def show
        summary = MonthSummary.new(user: current_user, year: year_param, month: month_param)
        render json: { month: month_as_json(summary) }
      rescue Date::Error, ArgumentError
        render json: { errors: [ I18n.t("api.invalid_month") ] }, status: :unprocessable_entity
      end

      private
        def year_param
          params[:year].to_i
        end

        def month_param
          params[:month].to_i
        end

        def month_as_json(summary)
          {
            "year" => summary.year,
            "month" => summary.month,
            "home_currency" => current_user.home_currency,
            "income_cents" => summary.income_home_cents,
            "subscriptions_cents" => summary.subscriptions_home_cents,
            "expenses_cents" => summary.expenses_home_cents,
            "leftover_cents" => summary.leftover_cents,
            "missing_rate_currencies" => summary.missing_rate_currencies,
            "salary_missing" => summary.salary_missing?,
            "subscriptions" => summary.subscriptions.map { |line| line_as_json(line) },
            "expenses" => summary.expenses.map { |line| line_as_json(line) },
            "payment_days" => summary.payment_days.map { |line| line_as_json(line) }
          }
        end

        def line_as_json(line)
          {
            "id" => line.id,
            "kind" => line.kind.to_s,
            "title" => line.title,
            "notes" => line.notes,
            "amount_cents" => line.amount_cents,
            "currency" => line.currency,
            "home_cents" => line.home_cents,
            "skipped" => line.skipped,
            "due_day" => line.due_day,
            "due_on" => line.due_on&.iso8601,
            "overdue" => line.overdue,
            "due_today" => line.due_today,
            "category" => line.category,
            "spent_on" => line.spent_on&.iso8601,
            "interval" => line.interval,
            "billing_month" => line.billing_month
          }
        end
    end
  end
end
