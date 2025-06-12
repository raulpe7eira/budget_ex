defmodule BudgetWeb.BudgetShowLiveTest do
  use BudgetWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Budget.Repo
  alias Budget.Tracking.BudgetTransaction

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

    test "redirects to budget list page when budget ID is not a uuid", %{conn: conn, user: user} do
      fake_budget_id = "invalid_uuid"

      conn = log_in_user(conn, user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{fake_budget_id}")
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

      assert has_element?(lv, "#transaction-modal")
    end

    test "creates a transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      params = params_for(:budget_transaction)

      form = form(lv, "#transaction-modal form", %{"transaction" => params})

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

      form = form(lv, "#transaction-modal form", %{"transaction" => params})

      html = render_change(form)

      assert html =~ "must be greater than 0"
    end

    test "validation errors are presented when form is submitted with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/new-transaction")

      params = params_for(:budget_transaction, amount: Decimal.new("-42"))

      form = form(lv, "#transaction-modal form", %{"transaction" => params})

      html = render_submit(form)

      assert html =~ "must be greater than 0"
    end
  end

  describe "Edit transaction modal" do
    setup ctx do
      transaction = insert(:budget_transaction, budget: ctx.budget)

      %{transaction: transaction}
    end

    test "shows edit transaction modal", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(conn, ~p"/budgets/#{ctx.budget}/transactions/#{ctx.transaction}/edit")

      assert has_element?(lv, "#transaction-modal")

      assert has_element?(
               lv,
               ~s|#transaction-modal input[name='transaction[description]'][value='#{ctx.transaction.description}']|
             )
    end

    test "redirects on invalid transaction id", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, conn} =
        live(conn, ~p"/budgets/#{ctx.budget}/transactions/invalid/edit")
        |> follow_redirect(conn, ~p"/budgets/#{ctx.budget}")

      assert %{"error" => "Transaction not found"} = conn.assigns.flash
    end

    test "validation errors are presented when form is changed with invalid input", ctx do
      conn = log_in_user(ctx.conn, ctx.user)

      {:ok, lv, _html} =
        live(conn, ~p"/budgets/#{ctx.budget}/transactions/#{ctx.transaction}/edit")

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
        live(conn, ~p"/budgets/#{ctx.budget}/transactions/#{ctx.transaction}/edit")

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
        live(conn, ~p"/budgets/#{ctx.budget}/transactions/#{ctx.transaction}/edit")

      new_amount = (:rand.uniform(5000) / 100) |> Decimal.from_float()

      params = params_for(:budget_transaction, amount: new_amount)

      form =
        form(lv, "#transaction-modal form", %{
          "transaction" => params
        })

      {:ok, _lv, html} =
        form
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Transaction updated"

      transaction = Repo.get(BudgetTransaction, ctx.transaction.id)
      assert transaction.amount == new_amount
    end
  end

  describe "Delete transaction" do
    setup ctx do
      transaction = insert(:budget_transaction, budget: ctx.budget)

      %{transaction: transaction}
    end

    test "deletes transaction", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, html} = live(conn, ~p"/budgets/#{ctx.budget}")

      assert html =~ ctx.transaction.description

      {:ok, _lv, html} =
        lv
        |> element(
          ~s|button[phx-click="delete_transaction"][phx-value-id="#{ctx.transaction.id}"]|
        )
        |> render_click()
        |> follow_redirect(conn, ~p"/budgets/#{ctx.budget}")

      refute html =~ ctx.transaction.description
      assert html =~ "Transaction deleted"
    end
  end
end
