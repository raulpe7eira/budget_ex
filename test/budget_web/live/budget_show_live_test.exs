defmodule BudgetWeb.BudgetShowLiveTest do
  use BudgetWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Budget.AccountsFixtures
  alias Budget.TrackingFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    budget = TrackingFixtures.budget_fixture(%{creator_id: user.id})

    %{user: user, budget: budget}
  end

  describe "Show budget" do
    test "shows budget when it exists", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets/#{ctx.budget}")

      assert html =~ ctx.budget.name
    end

    test "redirects to budget list page when budget does not exist", ctx do
      fake_budget_id = Ecto.UUID.generate()

      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        conn
        |> live(~p"/budgets/#{fake_budget_id}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Budget not found"} = conn.assigns.flash
    end

    test "redirects to budget list page when budget is hidden from the user", ctx do
      other_user = AccountsFixtures.user_fixture()

      conn = log_in_user(ctx.conn, other_user)

      {:ok, conn} =
        conn
        |> live(~p"/budgets/#{ctx.budget}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Budget not found"} = conn.assigns.flash
    end
  end
end
