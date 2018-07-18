defmodule Benny.Connection do
  use GenStateMachine
  require Logger

  ### API

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      # let connections die all the way, no matter what
      restart: :temporary,
      shutdown: 500
    }
  end

  def start_link(args) do
    GenStateMachine.start_link(__MODULE__, args)
  end

  def set_tcp_active(pid) do
    GenStateMachine.cast(pid, :set_tcp_active)
  end

  ### CALLBACKS

  def init(args) do
    data = args

    {
      :ok,
      :ready_to_receive,
      data,
      [{:next_event, :internal, :ready_to_receive}]
    }
  end

  def handle_event(:internal, :ready_to_receive, _state, _data) do
    :keep_state_and_data
  end

  def handle_event(:cast, :set_tcp_active, state, data) do
    :inet.setopts(data[:accept_socket], active: true)
    Logger.debug("Set to active TCP receive mode: #{inspect(data[:accept_socket])}")
    handle_event(:internal, :ready_to_receive, state, data)
  end

  ### TCP handlers

  def handle_event(:info, {:tcp, socket, packet}, _state, data) do
    Logger.debug("Received from #{data[:ip]}:#{data[:port]} #{inspect(socket)}: #{packet}")
    {:keep_state, data}
  end

  def handle_event(:info, {:tcp_error, socket, reason}, _state, data) do
    Logger.debug(
      "Socket error: #{data[:ip]}:#{data[:port]} #{inspect(socket)}: #{inspect(reason)}"
    )

    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_closed, socket}, _state, data) do
    Logger.debug("Socket closed: #{data[:ip]}:#{data[:port]} #{inspect(socket)}")
    {:stop, :normal}
  end
end
