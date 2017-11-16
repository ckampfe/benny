defmodule Benny.PeerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(socket) do
    Supervisor.start_child(__MODULE__, [socket])
  end

  def init(:ok) do
    Supervisor.init(
      [{Benny.Peer, []}],
      strategy: :simple_one_for_one
    )
  end
end