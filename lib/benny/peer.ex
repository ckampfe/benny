defmodule Benny.Peer do
  use GenStateMachine
  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_arg, socket) do
    GenStateMachine.start_link(__MODULE__, [socket])
  end

  def init(socket) do
    data =
      %{
        socket: socket
      }

    {:ok, :connected, data}
  end

  def handle_event(:info, {:tcp, socket, packet}, state, data) do
    Logger.debug("child process state: #{state}")
    Logger.debug("child process received from #{inspect(socket)}: #{packet}")

    {:keep_state, data}
  end

  def handle_event(:info, {:tcp_closed, socket}, state, data) do
    Logger.debug("child process state: #{state}")
    Logger.debug("child process view of socket #{inspect(socket)} closed")
    Logger.debug(
      inspect(Map.update(data, :sockets, MapSet.new(), fn(sockets) -> MapSet.delete(sockets, socket) end)[:sockets])
    )

    {
      :keep_state,
      data
    }
  end

  def handle_event(:info, {:tcp_error, socket, reason}, state, data) do
    {:next_state, state, data}
  end
end