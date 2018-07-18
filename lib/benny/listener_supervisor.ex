defmodule Benny.ListenerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(%{port: _port} = args) do
    Supervisor.init(
      [
        {Benny.Listener, args}
      ],
      strategy: :one_for_one
    )
  end
end
