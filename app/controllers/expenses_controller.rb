class ExpensesController < ApplicationController
  rate_limit to: 60, within: 1.minute, only: :create,
    by: -> { current_user.id },
    with: -> { redirect_back fallback_location: root_path, alert: I18n.t("auth.too_many") }

  def create
    expense = current_user.expenses.new(expense_params)
    save_expense(expense)
  end

  def update
    expense = current_user.expenses.find(params[:id])
    expense.assign_attributes(expense_params)
    save_expense(expense)
  end

  def destroy
    expense = current_user.expenses.find(params[:id])
    expense.destroy
    redirect_to month_url_for
  end

  private
    def expense_params
      params.require(:expense).permit(:title, :amount, :currency, :spent_on, :category, :notes)
    end

    def save_expense(expense)
      if expense.save
        redirect_to month_url_for
      else
        redirect_to month_url_for, alert: expense.errors.full_messages.to_sentence
      end
    end
end
