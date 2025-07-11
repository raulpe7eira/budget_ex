defmodule BudgetWeb.BudgetListLiveTest do
  use BudgetWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Budget.Tracking

  setup do
    %{user: insert(:user)}
  end

  describe "Index view" do
    test "shows budget when one exists", ctx do
      budget = insert(:budget, creator: ctx.user)

      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets")

      assert html =~ budget.name
      assert html =~ budget.description
    end
  end

  describe "Create budget modal" do
    test "modal is presented", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      assert has_element?(lv, "#create-budget-modal")
    end

    test "validation errors are presented when form is changed with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget, name: "")

      form = form(lv, "#create-budget-modal form", %{"create_budget" => %{"budget" => params}})

      html = render_change(form)

      assert html =~ html_escape("can't be blank")
    end

    test "creates a budget", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget)

      form = form(lv, "#create-budget-modal form", %{"create_budget" => %{"budget" => params}})

      submission_result = render_submit(form)

      assert [created_budget] = Tracking.list_budgets()

      {:ok, _lv, html} = follow_redirect(submission_result, conn, ~p"/budgets/#{created_budget}")

      assert html =~ "Budget created"
      assert html =~ params.name

      assert [created_budget] = Tracking.list_budgets()
      assert created_budget.name == params.name
      assert created_budget.description == params.description
      assert created_budget.start_date == params.start_date
      assert created_budget.end_date == params.end_date
    end

    test "creates a budget with period funding amount", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params =
        params_for(:budget,
          name: "Funded Budget",
          start_date: "2025-01-01",
          end_date: "2025-02-28"
        )

      form =
        form(lv, "#create-budget-modal form", %{
          "create_budget" => %{
            "period_funding_amount" => "1000.00",
            "budget" => params
          }
        })

      submission_result = render_submit(form)

      assert [created_budget] = Tracking.list_budgets()
      assert created_budget.name == "Funded Budget"

      assert [january_funding, february_funding] = Tracking.list_transactions(created_budget)
      assert january_funding.type == :funding
      assert january_funding.amount == Decimal.new("1000.00")
      assert january_funding.effective_date == ~D[2025-01-01]

      assert february_funding.type == :funding
      assert february_funding.amount == Decimal.new("1000.00")
      assert february_funding.effective_date == ~D[2025-02-01]

      {:ok, _lv, html} = follow_redirect(submission_result, conn, ~p"/budgets/#{created_budget}")

      assert html =~ "Budget created"
      assert html =~ "Funded Budget"
    end

    test "validation errors are presented when period funding amount is negative", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget)

      form =
        form(lv, "#create-budget-modal form", %{
          "create_budget" => %{
            "period_funding_amount" => "-100",
            "budget" => params
          }
        })

      html = render_change(form)

      assert html =~ "must be greater than or equal to 0"
    end

    test "validation errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget, name: "")

      form = form(lv, "#create-budget-modal form", %{"create_budget" => %{"budget" => params}})

      html = render_submit(form)

      assert html =~ html_escape("can't be blank")
    end

    test "validation date errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params =
        params_for(:budget,
          start_date: ~D[2025-12-01],
          end_date: ~D[2025-01-31]
        )

      form = form(lv, "#create-budget-modal form", %{"create_budget" => %{"budget" => params}})

      html = render_submit(form)

      assert html =~ "must end after start date"
    end
  end
end
