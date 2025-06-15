defmodule BudgetWeb.PeriodShowLive do
  use BudgetWeb, :live_view

  alias Budget.Tracking
  alias Budget.Tracking.BudgetTransaction

  def mount(%{"period_id" => period_id, "budget_id" => budget_id} = params, _session, socket)
      when is_uuid(period_id) and is_uuid(budget_id) do
    current_user = socket.assigns.current_user

    socket =
      case Tracking.get_budget_period(period_id,
             user: current_user,
             budget_id: budget_id,
             preload: :budget
           ) do
        nil ->
          socket
          |> put_flash(:error, "Not found")
          |> redirect(to: ~p"/budgets")

        period ->
          transactions =
            Tracking.list_transactions(period.budget_id,
              between: {period.start_date, period.end_date}
            )

          socket
          |> assign(period: period, transactions: transactions)
          |> apply_action(params)
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, "Not found")
      |> redirect(to: ~p"/budgets")

    {:ok, socket}
  end

  def apply_action(%{assigns: %{live_action: :edit_transaction}} = socket, %{
        "transaction_id" => transaction_id
      }) do
    transaction = Enum.find(socket.assigns.transactions, &(&1.id == transaction_id))

    if transaction do
      assign(socket, transaction: Map.put(transaction, :budget, socket.assigns.period.budget))
    else
      socket
      |> put_flash(:error, "Transaction not found")
      |> redirect(
        to: ~p"/budgets/#{socket.assigns.period.budget}/periods/#{socket.assigns.period}"
      )
    end
  end

  def apply_action(socket, _), do: socket

  def handle_event("delete_transaction", %{"id" => transaction_id}, socket) do
    transaction = Enum.find(socket.assigns.transactions, &(&1.id == transaction_id))

    socket =
      if transaction do
        case Tracking.delete_transaction(transaction) do
          {:ok, _} ->
            socket
            |> put_flash(:info, "Transaction deleted")
            |> push_navigate(
              to: ~p"/budgets/#{socket.assigns.period.budget}/periods/#{socket.assigns.period}",
              replace: true
            )

          {:error, _} ->
            put_flash(socket, :error, "Failed to delete transaction")
        end
      else
        put_flash(socket, :error, "Transaction not found")
      end

    {:noreply, socket}
  end

  defp default_transaction(assigns) do
    today = Date.utc_today()

    effective_date =
      cond do
        Date.before?(today, assigns.period.start_date) ->
          assigns.period.start_date

        Date.after?(today, assigns.period.end_date) ->
          assigns.period.end_date

        true ->
          today
      end

    %BudgetTransaction{
      effective_date: effective_date,
      budget: assigns.period.budget
    }
  end
end
