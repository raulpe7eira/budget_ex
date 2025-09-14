defmodule BudgetExWeb.BudgetShowLiveTest do
  use BudgetExWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias BudgetEx.Repo
  alias BudgetEx.Tracking.BudgetCollaborator
  alias BudgetExWeb.BudgetShowLive

  setup do
    budget = insert(:budget)

    period =
      insert(:budget_period,
        budget: budget,
        start_date: ~D[2025-01-01],
        end_date: ~D[2025-01-31]
      )

    %{budget: budget, user: budget.creator, period: period}
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

    test "redirects to budget list page when budget ID is not a uuid", ctx do
      fake_budget_id = "invalid_uuid"

      conn = log_in_user(ctx.conn, ctx.user)

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

  describe "Collaborators modal" do
    setup %{user: user} do
      budget = insert(:budget, creator: user)

      %{budget: budget}
    end

    test "redirects to login page when not signed in", ctx do
      assert {:error, redirect} = live(ctx.conn, ~p"/budgets/#{ctx.budget}/collaborators")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "modal is presented", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/collaborators")

      assert has_element?(lv, "#collaborators-modal")
      assert html =~ "Manage Access"
      assert html =~ ctx.user.name
    end

    test "modal shows collaborators", ctx do
      collaborators = insert_list(3, :budget_collaborator, budget: ctx.budget)

      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, _lv, html} = live(conn, ~p"/budgets/#{ctx.budget}/collaborators")

      assert html =~ "Collaborators (3)"
      assert html =~ ctx.user.name

      for collaborator <- collaborators do
        assert html =~ collaborator.user.name
        assert html =~ collaborator.user.email
      end
    end

    test "removes collaborator when clicked", ctx do
      [collaborator_one, collaborator_two] =
        insert_list(2, :budget_collaborator, budget: ctx.budget)

      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/collaborators")

      remove_button =
        element(
          lv,
          "button[phx-click='remove-collaborator'][phx-value-user-id='#{collaborator_two.user_id}']"
        )

      html = render_click(remove_button)

      assert html =~ collaborator_one.user.name
      refute html =~ collaborator_two.user.name
    end

    test "removes, informs, and redirects collaborator when they remove self", ctx do
      collaborator = insert(:budget_collaborator, budget: ctx.budget)

      conn = log_in_user(ctx.conn, collaborator.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/collaborators")

      remove_button =
        element(
          lv,
          "button[phx-click='remove-collaborator'][phx-value-user-id='#{collaborator.user_id}']"
        )

      {:ok, _lv, html} = render_click(remove_button) |> follow_redirect(conn, ~p"/budgets")

      assert html =~ "You have been removed from the budget"

      # Assert collaborator was removed
      refute Repo.get_by(BudgetCollaborator,
               user_id: collaborator.user_id,
               budget_id: ctx.budget.id
             )
    end

    test "changes text to copied on click of copy link button", ctx do
      conn = log_in_user(ctx.conn, ctx.user)
      {:ok, lv, _html} = live(conn, ~p"/budgets/#{ctx.budget}/collaborators")

      copy_button = element(lv, "button", "Copy Link")

      render_click(copy_button)

      refute has_element?(lv, "button", "Copy Link")
      assert has_element?(lv, "button", "Copied")
    end
  end

  describe "current_period_id/2" do
    setup do
      january_2025 = build(:budget_period, start_date: ~D[2025-01-01], end_date: ~D[2025-01-31])
      february_2025 = build(:budget_period, start_date: ~D[2025-02-01], end_date: ~D[2025-02-28])
      march_2025 = build(:budget_period, start_date: ~D[2025-03-01], end_date: ~D[2025-03-31])

      %{periods: [january_2025, february_2025, march_2025]}
    end

    test "returns nil with no periods" do
      assert BudgetShowLive.current_period_id([], ~D[2024-12-31]) == nil
    end

    test "returns nil if first period hasn't started yet", ctx do
      assert BudgetShowLive.current_period_id(ctx.periods, ~D[2024-12-31]) == nil
    end

    test "returns the january if date is in january", ctx do
      [january | _rest] = ctx.periods

      assert BudgetShowLive.current_period_id(ctx.periods, ~D[2025-01-15]) == january.id
    end

    test "returns the february if date is february first", ctx do
      [_january, february, _march] = ctx.periods

      assert BudgetShowLive.current_period_id(ctx.periods, ~D[2025-02-01]) == february.id
    end

    test "returns last period if date is after last period", ctx do
      [_january, _february, march] = ctx.periods

      assert BudgetShowLive.current_period_id(ctx.periods, ~D[2025-04-01]) == march.id
    end
  end

  describe "calculate_ending_balances/2" do
    test "does not crash with empty period list" do
      assert %{} = BudgetShowLive.calculate_ending_balances([], %{})
    end

    test "correctly calculates ending balances across four periods with sparse data" do
      periods = insert_list(4, :budget_period)
      [p1, p2, p3, p4] = periods

      summary = %{
        p1.id => %{
          funding: Decimal.new("7"),
          spending: Decimal.new("2")
        },
        p3.id => %{
          funding: Decimal.new("5")
        },
        p4.id => %{
          spending: Decimal.new("3")
        }
      }

      balances = BudgetShowLive.calculate_ending_balances(periods, summary)

      assert Map.get(balances, p1.id) == Decimal.new("5")
      assert Map.get(balances, p2.id) == Decimal.new("5")
      assert Map.get(balances, p3.id) == Decimal.new("10")
      assert Map.get(balances, p4.id) == Decimal.new("7")
    end
  end
end
