class SettingsController < ApplicationController
  def update
    current_user.assign_attributes(settings_params)
    current_user.fx_hash = fx_params
    if current_user.save
      redirect_to month_url_for, notice: t("app.settings_saved")
    else
      redirect_to month_url_for, alert: current_user.errors.full_messages.to_sentence
    end
  end

  private
    def settings_params
      params.require(:user).permit(:home_currency, :monthly_income, :income_currency)
    end

    def fx_params
      return {} if params[:fx].blank?

      params.require(:fx).permit(*Money::CURRENCIES).to_h
    end
end
