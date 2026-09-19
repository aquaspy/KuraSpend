module Api
  module V1
    class PaymentDaysController < Api::BaseController
      rate_limit to: 60, within: 1.minute, only: %i[create update],
        by: -> { current_api_token.id },
        with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      def index
        days = current_user.payment_days.order(:due_day, :id).map(&:as_api)
        render json: { payment_days: days }
      end

      def show
        day = current_user.payment_days.find_by(id: params[:id])
        return render_not_found unless day

        render json: { payment_day: day.as_api }
      end

      def create
        day = current_user.payment_days.new(payment_day_params)
        if day.save
          render json: { payment_day: day.as_api }, status: :created
        else
          render_unprocessable(day)
        end
      end

      def update
        day = current_user.payment_days.find_by(id: params[:id])
        return render_not_found unless day

        if day.update(payment_day_params)
          render json: { payment_day: day.as_api }
        else
          render_unprocessable(day)
        end
      end

      def destroy
        day = current_user.payment_days.find_by(id: params[:id])
        return render_not_found unless day

        day.destroy
        head :no_content
      end

      private
        def payment_day_params
          nested = params[:payment_day]
          source = nested.is_a?(ActionController::Parameters) ? nested : params
          source.permit(:title, :due_day, :notes, :active)
        end
    end
  end
end
