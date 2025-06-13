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

      form = form(lv, "#create-budget-modal form", %{"budget" => params})

      html = render_change(form)

      assert html =~ html_escape("can't be blank")
    end

    test "creates a budget", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget)

      form = form(lv, "#create-budget-modal form", %{"budget" => params})

      {:ok, _lv, html} =
        form
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Budget created"
      assert html =~ params.name

      assert [created_budget] = Tracking.list_budgets()
      assert created_budget.name == params.name
      assert created_budget.description == params.description
      assert created_budget.start_date == params.start_date
      assert created_budget.end_date == params.end_date
    end

    test "validation errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      params = params_for(:budget, name: "")

      form = form(lv, "#create-budget-modal form", %{"budget" => params})

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

      form = form(lv, "#create-budget-modal form", %{"budget" => params})

      html = render_submit(form)

      assert html =~ "must end after start date"
    end
  end
end
