require "test_helper"

class ApiV1Test < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ada@example.com", password: "secret-password")
    @token = ApiToken.generate_for(@user, name: "hermes")
    @token.save!
    @auth = { "Authorization" => "Bearer #{@token.raw_token}" }
  end

  test "requests without a token are rejected" do
    get api_v1_expenses_path
    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "requests with a bogus token are rejected" do
    get api_v1_expenses_path, headers: { "Authorization" => "Bearer kura_bogus" }
    assert_response :unauthorized
  end

  test "lists expenses for a month filtered by category" do
    @user.expenses.create!(title: "Lunch", amount: "25.50", currency: "BRL", spent_on: "2026-09-10", category: "food")
    @user.expenses.create!(title: "Bus", amount: "6.00", currency: "BRL", spent_on: "2026-09-11", category: "transport")

    get api_v1_expenses_path(month: "2026-09", category: "food"), headers: @auth
    assert_response :success
    expenses = JSON.parse(response.body)["expenses"]
    assert_equal [ "Lunch" ], expenses.map { |expense| expense["title"] }
    assert_equal 2550, expenses.first["amount_cents"]
  end

  test "an agent can log, read, update and delete an expense" do
    post api_v1_expenses_path, headers: @auth, as: :json, params: {
      expense: { title: "Coffee", amount: "4.50", currency: "BRL", spent_on: "2026-09-19", category: "food" }
    }
    assert_response :created
    created = JSON.parse(response.body)["expense"]
    assert_equal 450, created["amount_cents"]
    id = created["id"]

    get api_v1_expense_path(id), headers: @auth
    assert_response :success
    assert_equal "Coffee", JSON.parse(response.body)["expense"]["title"]

    patch api_v1_expense_path(id), headers: @auth, as: :json, params: {
      expense: { category: "leisure" }
    }
    assert_response :success
    assert_equal "leisure", JSON.parse(response.body)["expense"]["category"]

    delete api_v1_expense_path(id), headers: @auth
    assert_response :no_content
    assert_nil @user.expenses.find_by(id: id)
  end

  test "expenses accept integer cents and flat params" do
    post api_v1_expenses_path, headers: @auth, as: :json, params: {
      title: "Flat", amount_cents: 1999, currency: "USD", spent_on: "2026-09-19"
    }
    assert_response :created
    assert_equal 1999, JSON.parse(response.body)["expense"]["amount_cents"]
  end

  test "invalid expenses return errors" do
    post api_v1_expenses_path, headers: @auth, as: :json, params: {
      expense: { title: "" }
    }
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "invalid month filters return errors" do
    get api_v1_expenses_path(month: "september"), headers: @auth
    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "an agent can manage subscriptions" do
    post api_v1_subscriptions_path, headers: @auth, as: :json, params: {
      subscription: { title: "Music", amount: "19.90", currency: "BRL", interval: "monthly" }
    }
    assert_response :created
    id = JSON.parse(response.body)["subscription"]["id"]

    get api_v1_subscriptions_path, headers: @auth
    assert_response :success
    assert_equal [ "Music" ], JSON.parse(response.body)["subscriptions"].map { |row| row["title"] }

    patch api_v1_subscription_path(id), headers: @auth, as: :json, params: {
      subscription: { active: false }
    }
    assert_response :success
    assert_equal false, JSON.parse(response.body)["subscription"]["active"]

    delete api_v1_subscription_path(id), headers: @auth
    assert_response :no_content
    assert_nil @user.subscriptions.find_by(id: id)
  end

  test "an agent can manage payment days" do
    post api_v1_payment_days_path, headers: @auth, as: :json, params: {
      payment_day: { title: "Water", due_day: 10 }
    }
    assert_response :created
    id = JSON.parse(response.body)["payment_day"]["id"]

    get api_v1_payment_days_path, headers: @auth
    assert_response :success
    assert_equal [ "Water" ], JSON.parse(response.body)["payment_days"].map { |row| row["title"] }

    patch api_v1_payment_day_path(id), headers: @auth, as: :json, params: {
      payment_day: { due_day: 12 }
    }
    assert_response :success
    assert_equal 12, JSON.parse(response.body)["payment_day"]["due_day"]

    delete api_v1_payment_day_path(id), headers: @auth
    assert_response :no_content
    assert_nil @user.payment_days.find_by(id: id)
  end

  test "month summary reports totals in the home currency" do
    @user.update!(monthly_income_cents: 500_000, income_currency: "BRL", home_currency: "BRL")
    @user.subscriptions.create!(title: "Music", amount: "20.00", currency: "BRL", interval: "monthly")
    @user.expenses.create!(title: "Lunch", amount: "30.00", currency: "BRL", spent_on: "2026-09-10", category: "food")

    get api_v1_month_path(year: 2026, month: 9), headers: @auth
    assert_response :success
    month = JSON.parse(response.body)["month"]
    assert_equal "BRL", month["home_currency"]
    assert_equal 495_000, month["leftover_cents"]
    assert_equal [ "Lunch" ], month["expenses"].map { |row| row["title"] }
  end

  test "one user cannot touch another user's expenses" do
    expense = @user.expenses.create!(title: "Secret", amount: "1.00", currency: "BRL", spent_on: "2026-09-10")
    other = User.create!(email: "other@example.com", password: "secret-password")
    other_token = ApiToken.generate_for(other, name: "other")
    other_token.save!

    get api_v1_expense_path(expense), headers: { "Authorization" => "Bearer #{other_token.raw_token}" }
    assert_response :not_found
  end

  test "revoked tokens stop working" do
    @token.destroy
    get api_v1_expenses_path, headers: @auth
    assert_response :unauthorized
  end

  test "tokens keep working while the app is locked" do
    post login_path, params: { email: @user.email, password: "secret-password" }
    post lock_path
    assert_redirected_to unlock_path

    get api_v1_expenses_path, headers: @auth
    assert_response :success
  end

  test "using a token records its last use" do
    assert_nil @token.last_used_at
    get api_v1_expenses_path, headers: @auth
    assert_response :success
    assert_not_nil @token.reload.last_used_at
  end
end
