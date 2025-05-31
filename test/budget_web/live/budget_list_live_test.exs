defmodule BudgetWeb.BudgetListLiveTest do
  use BudgetWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Budget.AccountsFixtures
  alias Budget.Tracking
  alias Budget.TrackingFixtures

  setup do
    user = AccountsFixtures.user_fixture()

    %{user: user}
  end

  describe "Index view" do
    test "shows budget when one exists", ctx do
      budget = TrackingFixtures.budget_fixture(%{creator_id: ctx.user.id})

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

      form = element(lv, "#create-budget-modal form")

      html =
        render_change(form, %{
          "budget" => %{"name" => ""}
        })

      assert html =~ html_escape("can't be blank")
    end

    test "creates a budget", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/new")

      form = form(lv, "#create-budget-modal form")

      {:ok, _lv, html} =
        render_submit(form, %{
          "budget" => %{
            "name" => "New name",
            "description" => "New description",
            "start_date" => "2025-01-01",
            "end_date" => "2025-01-31"
          }
        })
        |> follow_redirect(conn)

      assert html =~ "Budget created"
      assert html =~ "New name"

      assert [created_budget] = Tracking.list_budgets()
      assert created_budget.name == "New name"
      assert created_budget.description == "New description"
      assert created_budget.start_date == ~D[2025-01-01]
      assert created_budget.end_date == ~D[2025-01-31]
    end
  end
end
