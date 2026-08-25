require "test_helper"
require "tempfile"

class SpendFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ada@example.com", password: "secret-password")
  end

  test "signup can be turned off" do
    ENV["SIGNUP_ENABLED"] = "false"
    get signup_path
    assert_redirected_to login_path
    follow_redirect!
    refute_includes response.body, I18n.t("auth.create_one")

    assert_no_difference -> { User.count } do
      post signup_path, params: { email: "intruder@example.com", password: "secret-password", password_confirmation: "secret-password" }
    end
    assert_redirected_to login_path
  ensure
    ENV.delete("SIGNUP_ENABLED")
  end

  test "signup creates a user with a real password" do
    post signup_path, params: { email: "lin@example.com", password: "secret-password", password_confirmation: "secret-password" }
    assert_redirected_to root_path
    user = User.find_by(email: "lin@example.com")
    assert user
    assert user.authenticate("secret-password")
    refute user.authenticate("wrong")
  end

  test "login opens the month" do
    post login_path, params: { email: @user.email, password: "secret-password" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_includes response.body, "KuraSpend"
    assert_select ".hero"
    assert_select ".hero[data-leftover=0]"
  end

  test "strangers cannot read spend" do
    get root_path
    assert_redirected_to login_path
  end

  test "salary subscriptions expenses show leftover and payment days do not" do
    login
    patch settings_path, params: {
      year: 2026, month: 8,
      user: { monthly_income: "10000", home_currency: "BRL", income_currency: "BRL" },
      fx: { USD: "5.45" }
    }
    post subscriptions_path, params: { year: 2026, month: 8, subscription: { title: "Netflix", amount: "50", currency: "BRL", interval: "monthly" } }
    post payment_days_path, params: { year: 2026, month: 8, payment_day: { title: "Water", due_day: 10 } }
    post expenses_path, params: { year: 2026, month: 8, expense: { title: "Coffee", amount: "15", currency: "BRL", spent_on: "2026-08-12" } }

    get month_path(year: 2026, month: 8)
    assert_response :success
    assert_includes response.body, "Netflix"
    assert_includes response.body, "Water"
    assert_includes response.body, "Coffee"
    leftover = 1_000_000 - 5_000 - 1_500
    assert_select ".hero[data-leftover=?]", leftover.to_s
  end

  test "another user cannot touch an expense" do
    expense = @user.expenses.create!(title: "Secret", amount_cents: 500, currency: "BRL", spent_on: Date.new(2026, 8, 25))
    User.create!(email: "other@example.com", password: "secret-password")
    post login_path, params: { email: "other@example.com", password: "secret-password" }
    patch expense_path(expense), params: { expense: { title: "Stolen" } }
    assert_response :not_found
    assert_equal "Secret", expense.reload.title
  end

  test "export and import round-trip" do
    login
    @user.subscriptions.create!(title: "Spotify", amount_cents: 3_400, currency: "BRL")
    @user.expenses.create!(title: "Lunch", amount_cents: 2_000, currency: "BRL", spent_on: Date.new(2026, 8, 20))
    get export_path
    assert_response :success
    payload = response.body
    json = JSON.parse(payload)
    assert_equal "KuraSpend", json["app"]
    assert_equal 1, json["subscriptions"].size

    other = User.create!(email: "other@example.com", password: "secret-password")
    post login_path, params: { email: other.email, password: "secret-password" }
    file = Tempfile.new([ "spend", ".json" ])
    file.write(payload)
    file.flush
    post import_path, params: { file: Rack::Test::UploadedFile.new(file.path, "application/json") }
    follow_redirect!
    assert_equal 1, other.subscriptions.count
    assert_equal 1, other.expenses.count
  ensure
    file&.close!
    file&.unlink
  end

  test "service worker uses the kuraspend cache" do
    login
    get pwa_service_worker_path(format: :js)
    assert_response :success
    assert_includes response.body, 'const CACHE = "kuraspend-v1"'
  end

  test "previous month still renders" do
    login
    get month_path(year: 2026, month: 7)
    assert_response :success
    assert_select ".hero"
  end

  private
    def login
      post login_path, params: { email: @user.email, password: "secret-password" }
    end
end
