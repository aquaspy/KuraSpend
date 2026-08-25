class PaymentDaysController < ApplicationController
  rate_limit to: 60, within: 1.minute, only: :create,
    by: -> { current_user.id },
    with: -> { redirect_back fallback_location: root_path, alert: I18n.t("auth.too_many") }

  def create
    day = current_user.payment_days.new(payment_day_params)
    save_day(day)
  end

  def update
    day = current_user.payment_days.find(params[:id])
    day.assign_attributes(payment_day_params)
    save_day(day)
  end

  def destroy
    current_user.payment_days.find(params[:id]).destroy
    redirect_to month_url_for
  end

  private
    def payment_day_params
      params.require(:payment_day).permit(:title, :due_day, :notes, :active)
    end

    def save_day(day)
      if day.save
        redirect_to month_url_for
      else
        redirect_to month_url_for, alert: day.errors.full_messages.to_sentence
      end
    end
end
