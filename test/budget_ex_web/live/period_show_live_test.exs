defmodule BudgetExWeb.PeriodShowLiveTest do
  use BudgetExWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BudgetEx.Repo
  alias BudgetEx.Tracking.BudgetTransaction

  setup do
    budget = insert(:budget)

    period =
      insert(:budget_period, budget: budget, start_date: ~D[2025-01-01], end_date: ~D[2025-01-31])

    %{budget: budget, period: period, user: budget.creator}
  end

  describe "Show period" do
    test "shows period when it exists", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      assert html =~ ctx.budget.name
    end

    test "shows empty state when no transactions exist", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      assert html =~ "No transactions yet"
    end

    test "shows transaction when it exists", ctx do
      transaction =
        insert(:budget_transaction, budget: ctx.budget, effective_date: ~D[2025-01-15])

      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      assert html =~ transaction.description
    end

    test "redirects to budget list page when period does not exist", ctx do
      fake_budget_id = Ecto.UUID.generate()
      fake_period_id = Ecto.UUID.generate()

      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{fake_budget_id}/periods/#{fake_period_id}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Not found"} = conn.assigns.flash
    end

    test "redirects to budget list page when period ID is not a uuid", ctx do
      fake_budget_id = Ecto.UUID.generate()
      fake_period_id = "invalid_uuid"

      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{fake_budget_id}/periods/#{fake_period_id}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Not found"} = conn.assigns.flash
    end

    test "redirects to budget list page when budget ID is not a uuid", ctx do
      fake_budget_id = "invalid_uuid"
      fake_period_id = Ecto.UUID.generate()

      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{fake_budget_id}/periods/#{fake_period_id}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Not found"} = conn.assigns.flash
    end

    test "redirects to budget list page when budget is hidden from the user", ctx do
      other_user = insert(:user)

      conn = log_in_user(ctx.conn, other_user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")
        |> follow_redirect(conn, ~p"/budgets")

      assert %{"error" => "Not found"} = conn.assigns.flash
    end
  end

  describe "Create transaction modal" do
    test "modal is presented", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/new-transaction")

      assert has_element?(lv, "#transaction-modal")
    end

    test "creates a transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/new-transaction")

      params = params_for(:budget_transaction)

      form =
        form(lv, "#transaction-modal form", %{
          "transaction" => params
        })

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn)

      assert html =~ "Transaction created"
      assert html =~ params.description
    end
  end

  describe "Edit transaction modal" do
    setup %{budget: budget} do
      transaction = insert(:budget_transaction, budget: budget, effective_date: ~D[2025-01-15])

      %{transaction: transaction}
    end

    test "shows edit transaction modal", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(
          conn,
          ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/transactions/#{ctx.transaction}/edit"
        )

      assert has_element?(lv, "#transaction-modal")

      assert has_element?(
               lv,
               ~s|#transaction-modal input[name='transaction[description]'][value='#{ctx.transaction.description}']|
             )
    end

    test "redirects on invalid transaction id", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/transactions/invalid/edit")
        |> follow_redirect(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      assert %{"error" => "Transaction not found"} = conn.assigns.flash
    end

    test "validation errors are presented when form is changed with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(
          conn,
          ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/transactions/#{ctx.transaction}/edit"
        )

      params = params_for(:budget_transaction, amount: Decimal.new("-42"))

      form =
        form(lv, "#transaction-modal form", %{
          "transaction" => params
        })

      html = render_change(form)

      assert html =~ "must be greater than 0"
    end

    test "validation errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(
          conn,
          ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/transactions/#{ctx.transaction}/edit"
        )

      params = params_for(:budget_transaction, amount: Decimal.new("-42"))

      form =
        form(lv, "#transaction-modal form", %{
          "transaction" => params
        })

      html = render_submit(form)

      assert html =~ "must be greater than 0"
    end

    test "updates transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(
          conn,
          ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}/transactions/#{ctx.transaction}/edit"
        )

      new_amount = (:rand.uniform(5000) / 100) |> Decimal.from_float()

      params = params_for(:budget_transaction, amount: new_amount)

      form =
        form(lv, "#transaction-modal form", %{
          "transaction" => params
        })

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn)

      assert html =~ "Transaction updated"

      transaction = Repo.get(BudgetTransaction, ctx.transaction.id)
      assert transaction.amount == new_amount
    end
  end

  describe "Delete transaction" do
    setup %{budget: budget} do
      transaction = insert(:budget_transaction, budget: budget, effective_date: ~D[2025-01-15])

      %{transaction: transaction}
    end

    test "deletes transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      assert html =~ ctx.transaction.description

      delete_button =
        element(
          lv,
          ~s|button[phx-click="delete_transaction"][phx-value-id="#{ctx.transaction.id}"]|
        )

      {:ok, _lv, html} =
        render_click(delete_button)
        |> follow_redirect(conn, ~p"/budgets/#{ctx.budget}/periods/#{ctx.period}")

      refute html =~ ctx.transaction.description
      assert html =~ "Transaction deleted"
    end
  end
end
