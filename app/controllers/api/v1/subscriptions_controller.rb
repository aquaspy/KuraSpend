module Api
  module V1
    class SubscriptionsController < Api::BaseController
      rate_limit to: 60, within: 1.minute, only: %i[create update],
        by: -> { current_api_token.id },
        with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      def index
        scope = current_user.subscriptions.order(:title, :id)
        scope = scope.active if params[:active] == "true"
        render json: { subscriptions: scope.map(&:as_api) }
      end

      def show
        subscription = current_user.subscriptions.find_by(id: params[:id])
        return render_not_found unless subscription

        render json: { subscription: subscription.as_api }
      end

      def create
        subscription = current_user.subscriptions.new(subscription_params)
        if subscription.save
          render json: { subscription: subscription.as_api }, status: :created
        else
          render_unprocessable(subscription)
        end
      end

      def update
        subscription = current_user.subscriptions.find_by(id: params[:id])
        return render_not_found unless subscription

        if subscription.update(subscription_params)
          render json: { subscription: subscription.as_api }
        else
          render_unprocessable(subscription)
        end
      end

      def destroy
        subscription = current_user.subscriptions.find_by(id: params[:id])
        return render_not_found unless subscription

        subscription.destroy
        head :no_content
      end

      private
        def subscription_params
          nested = params[:subscription]
          source = nested.is_a?(ActionController::Parameters) ? nested : params
          permitted = source.permit(:title, :amount, :amount_cents, :currency, :interval, :due_day, :billing_month, :active, :notes)
          permitted.delete(:amount) if permitted[:amount_cents].present?
          permitted
        end
    end
  end
end
