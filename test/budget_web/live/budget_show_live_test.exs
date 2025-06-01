defmodule BudgetWeb.BudgetShowLiveTest do
  use BudgetWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    budget = insert(:budget)

    %{budget: budget, user: budget.creator}
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
      other_user = insert(:user)

      conn = log_in_user(ctx.conn, other_user)

      {:ok, conn} =
        conn
        |> live(~p"/budgets/#{ctx.budget}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Budget not found"} = conn.assigns.flash
    end
  end

  describe "Create transaction modal" do
    test "modal is presented", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      assert has_element?(lv, "#create-transaction-modal")
    end

    test "creates a transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      params = params_for(:budget_transaction)

      form = form(lv, "#create-transaction-modal form", %{"transaction" => params})

      {:ok, _lv, html} =
        form
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Transaction created"
      assert html =~ params.description
    end

    test "validation errors are presented when form is changed with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      params = params_for(:budget_transaction, amount: Decimal.new("-42"))

      form = form(lv, "#create-transaction-modal form", %{"transaction" => params})

      html = render_change(form)

      assert html =~ "must be greater than 0"
    end

    test "validation errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      params = params_for(:budget_transaction, amount: Decimal.new("-42"))

      form = form(lv, "#create-transaction-modal form", %{"transaction" => params})

      html = render_submit(form)

      assert html =~ "must be greater than 0"
    end
  end
end
