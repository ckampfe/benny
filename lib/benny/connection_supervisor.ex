defmodule Benny.ConnectionSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init(
      [{Benny.Connection, [6881]}],
      strategy: :one_for_one
    )
  end
end
