class SubscriptionsController < ApplicationController
  rate_limit to: 60, within: 1.minute, only: :create,
    by: -> { current_user.id },
    with: -> { redirect_back fallback_location: root_path, alert: I18n.t("auth.too_many") }

  def create
    subscription = current_user.subscriptions.new(subscription_params)
    save_subscription(subscription)
  end

  def update
    subscription = current_user.subscriptions.find(params[:id])
    subscription.assign_attributes(subscription_params)
    save_subscription(subscription)
  end

  def destroy
    current_user.subscriptions.find(params[:id]).destroy
    redirect_to month_url_for
  end

  private
    def subscription_params
      params.require(:subscription).permit(:title, :amount, :currency, :interval, :due_day, :billing_month, :active, :notes)
    end

    def save_subscription(subscription)
      if subscription.save
        redirect_to month_url_for
      else
        redirect_to month_url_for, alert: subscription.errors.full_messages.to_sentence
      end
    end
end
