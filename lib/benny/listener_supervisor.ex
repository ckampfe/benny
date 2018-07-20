defmodule Benny.ListenerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(%{port_range: _port_range} = args) do
    Supervisor.init(
      [
        {Benny.Listener, args}
      ],
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 5
    )
  end
end
