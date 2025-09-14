defmodule BudgetExWeb.CollaboratorsDialog do
  use BudgetExWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(link_copied: false)

    {:ok, socket}
  end

  @impl true
  def handle_event("copied", _params, socket) do
    {:noreply, assign(socket, link_copied: true)}
  end
end
