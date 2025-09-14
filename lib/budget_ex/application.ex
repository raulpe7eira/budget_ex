defmodule BudgetEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BudgetExWeb.Telemetry,
      BudgetEx.Repo,
      {DNSCluster, query: Application.get_env(:budget_ex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BudgetEx.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BudgetEx.Finch},
      # Start a worker by calling: BudgetEx.Worker.start_link(arg)
      # {BudgetEx.Worker, arg},
      # Start to serve requests, typically the last entry
      BudgetExWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BudgetEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BudgetExWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
