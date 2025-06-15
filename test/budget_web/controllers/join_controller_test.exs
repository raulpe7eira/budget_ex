defmodule BudgetWeb.JoinControllerTest do
  use BudgetWeb.ConnCase, async: true

  alias Budget.Repo
  alias Budget.Tracking.BudgetCollaborator

  setup do
    join_link = insert(:budget_join_link)

    %{join_link: join_link, budget: join_link.budget, creator: join_link.budget.creator}
  end

  describe "GET /join/:code" do
    test "redirects to root when code is invalid", ctx do
      conn = get(ctx.conn, ~p"/join/invalid")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Budget not found"
    end

    test "redirects to budget when joining as creator", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.creator)
        |> get(~p"/join/#{ctx.join_link.code}")

      assert redirected_to(conn) == ~p"/budgets/#{ctx.budget}"
    end

    test "redirects to budget when joining as existing collaborator", ctx do
      existing_collaborator = insert(:budget_collaborator, budget: ctx.budget)

      conn =
        ctx.conn
        |> log_in_user(existing_collaborator.user)
        |> get(~p"/join/#{ctx.join_link.code}")

      assert redirected_to(conn) == ~p"/budgets/#{ctx.budget}"
    end

    test "shows join page when unauthenticated", ctx do
      conn = get(ctx.conn, ~p"/join/#{ctx.join_link.code}")

      html = html_response(conn, 200)

      assert html =~ html_escape("Collaborate on #{ctx.creator.name}’s budget")
      assert html =~ ctx.budget.name
      assert html =~ ctx.budget.description
      assert html =~ "You'll need to create an account"
    end

    test "shows join page when signed in", ctx do
      user = insert(:user)

      conn =
        ctx.conn
        |> log_in_user(user)
        |> get(~p"/join/#{ctx.join_link.code}")

      html = html_response(conn, 200)

      assert html =~ html_escape("Collaborate on #{ctx.creator.name}’s budget")
      assert html =~ ctx.budget.name
      assert html =~ ctx.budget.description
      assert html =~ user.email
      refute html =~ "You'll need to create an account"
    end
  end

  describe "POST /join/:code" do
    test "redirects to root when code is invalid", ctx do
      user = insert(:user)

      conn =
        ctx.conn
        |> log_in_user(user)
        |> post(~p"/join/invalid")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Budget not found"
    end

    test "redirects to budget when joining as creator", ctx do
      conn =
        ctx.conn
        |> log_in_user(ctx.creator)
        |> post(~p"/join/#{ctx.join_link.code}")

      assert redirected_to(conn) == ~p"/budgets/#{ctx.budget}"
    end

    test "redirects to budget when joining as existing collaborator", ctx do
      existing_collaborator = insert(:budget_collaborator, budget: ctx.budget)

      conn =
        ctx.conn
        |> log_in_user(existing_collaborator.user)
        |> post(~p"/join/#{ctx.join_link.code}")

      assert redirected_to(conn) == ~p"/budgets/#{ctx.budget}"
    end

    test "adds user as collaborator", ctx do
      user = insert(:user)

      conn =
        ctx.conn
        |> log_in_user(user)
        |> post(~p"/join/#{ctx.join_link.code}")

      assert redirected_to(conn) == ~p"/budgets/#{ctx.budget}"

      assert Repo.get_by!(BudgetCollaborator, user_id: user.id)
    end
  end
end
