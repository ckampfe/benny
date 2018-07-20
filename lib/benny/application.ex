defmodule Benny.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Benny.TorrentRegistry},
      {Benny.FleetSupervisor, []},
      {Benny.ConnectionSupervisor, []},
      {Benny.ListenerSupervisor, %{port_range: 6881..50000}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Benny.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
