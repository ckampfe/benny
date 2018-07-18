defmodule Benny.ConnectionSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(accept_socket) do
    Logger.debug("Starting controlling process for #{inspect(accept_socket)}")
    DynamicSupervisor.start_child(__MODULE__, {Benny.Connection, accept_socket})
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
