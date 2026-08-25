class ApplicationController < ActionController::Base
  include Authentication
  include Locale
  include Locking

  allow_browser versions: :modern unless Rails.env.test?
  stale_when_importmap_changes

  private
    def month_url_for(date = nil)
      date ||= month_from_params || Date.current
      month_path(year: date.year, month: date.month)
    end

    def month_from_params
      Date.new(params[:year].to_i, params[:month].to_i, 1)
    rescue Date::Error, TypeError, ArgumentError
      nil
    end
end
