module Api
  module V1
    class ExpensesController < Api::BaseController
      rate_limit to: 60, within: 1.minute, only: %i[create update],
        by: -> { current_api_token.id },
        with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      def index
        start_on, end_on = month_range_param
        scope = current_user.expenses.where(spent_on: start_on..end_on).order(spent_on: :desc, id: :desc)
        scope = scope.where(category: params[:category].to_s) if params[:category].present?
        render json: { expenses: scope.map(&:as_api) }
      rescue Date::Error, ArgumentError
        render json: { errors: [ I18n.t("api.invalid_month") ] }, status: :unprocessable_entity
      end

      def show
        expense = current_user.expenses.find_by(id: params[:id])
        return render_not_found unless expense

        render json: { expense: expense.as_api }
      end

      def create
        expense = current_user.expenses.new(expense_params)
        if expense.save
          render json: { expense: expense.as_api }, status: :created
        else
          render_unprocessable(expense)
        end
      end

      def update
        expense = current_user.expenses.find_by(id: params[:id])
        return render_not_found unless expense

        if expense.update(expense_params)
          render json: { expense: expense.as_api }
        else
          render_unprocessable(expense)
        end
      end

      def destroy
        expense = current_user.expenses.find_by(id: params[:id])
        return render_not_found unless expense

        expense.destroy
        head :no_content
      end

      private
        def expense_params
          nested = params[:expense]
          source = nested.is_a?(ActionController::Parameters) ? nested : params
          permitted = source.permit(:title, :amount, :amount_cents, :currency, :spent_on, :category, :notes)
          permitted.delete(:amount) if permitted[:amount_cents].present?
          permitted
        end

        def month_range_param
          value = params[:month].presence || Date.current.strftime("%Y-%m")
          parts = value.to_s.split("-", 2).map(&:to_i)
          start_on = Date.new(parts[0].to_i, parts[1].to_i, 1)
          [ start_on, start_on.end_of_month ]
        end
    end
  end
end
