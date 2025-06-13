defmodule BudgetWeb.BudgetShowLive do
  use BudgetWeb, :live_view

  alias Budget.Tracking
  alias Budget.Tracking.BudgetTransaction

  def mount(%{"budget_id" => id} = params, _session, socket) when is_uuid(id) do
    budget =
      Tracking.get_budget(id,
        user: socket.assigns.current_user,
        preload: [:creator, :periods]
      )

    socket =
      if budget do
        summary = Tracking.summarize_transactions(budget)
        transactions = Tracking.list_transactions(budget)

        socket
        |> assign(budget: budget, summary: summary, transactions: transactions)
        |> apply_action(params)
      else
        socket
        |> put_flash(:error, "Budget not found")
        |> redirect(to: ~p"/budgets")
      end

    {:ok, socket}
  end

  def mount(_invalid_id, _session, socket) do
    socket =
      socket
      |> put_flash(:error, "Budget not found")
      |> redirect(to: ~p"/budgets")

    {:ok, socket}
  end

  def apply_action(%{assigns: %{live_action: :edit_transaction}} = socket, %{
        "transaction_id" => transaction_id
      }) do
    transaction = Enum.find(socket.assigns.transactions, &(&1.id == transaction_id))

    if transaction do
      assign(socket, transaction: transaction)
    else
      socket
      |> put_flash(:error, "Transaction not found")
      |> redirect(to: ~p"/budgets/#{socket.assigns.budget}")
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
            |> push_navigate(to: ~p"/budgets/#{socket.assigns.budget.id}", replace: true)

          {:error, _} ->
            put_flash(socket, :error, "Failed to delete transaction")
        end
      else
        put_flash(socket, :error, "Transaction not found")
      end

    {:noreply, socket}
  end

  defp default_transaction, do: %BudgetTransaction{effective_date: Date.utc_today()}

  @doc """
  Renders a transaction amount as a currency value, considering the type of the transaction.

  ## Example

  <.transaction_amount transaction={%BudgetTransaction{type: :spending, amount: Decimal.new("24.05")}} />

  Output:
  <span class="tabular-nums text-red-500">-24.05</span>
  """

  attr :transaction, BudgetTransaction, required: true

  def transaction_amount(%{transaction: %{type: :spending, amount: amount}}),
    do: currency(%{amount: Decimal.negate(amount)})

  def transaction_amount(%{transaction: %{type: :funding, amount: amount}}),
    do: currency(%{amount: amount})

  @doc """
  Renders a currency amount field.

  ## Example

  <.currency amount={Decimal.new("246.01")} />

  Output:
  <span class="tabular-nums text-green-500">246.01</span>
  """
  attr :amount, Decimal, required: true
  attr :class, :string, default: nil
  attr :positive_class, :string, default: "text-green-500"
  attr :negative_class, :string, default: "text-red-500"

  def currency(assigns) do
    ~H"""
    <span class={[
      "tabular-nums",
      Decimal.gte?(@amount, 0) && @positive_class,
      Decimal.lt?(@amount, 0) && @negative_class,
      @class
    ]}>
      {Decimal.round(@amount, 2)}
    </span>
    """
  end
end
