defmodule Legalmation.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LegalmationWeb.Telemetry,
      Legalmation.Repo,
      {DNSCluster, query: Application.get_env(:legalmation, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Legalmation.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Legalmation.Finch},
      # Start a worker by calling: Legalmation.Worker.start_link(arg)
      # {Legalmation.Worker, arg},
      # Start to serve requests, typically the last entry
      LegalmationWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Legalmation.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LegalmationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
