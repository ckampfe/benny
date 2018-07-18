defmodule Benny.Listener do
  use GenStateMachine
  alias Benny.{Connection, ConnectionSupervisor}
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

  def start_link(%{port: _port} = args) do
    GenStateMachine.start_link(__MODULE__, args)
  end

  def init(args) do
    data = args

    {
      :ok,
      :initializing_listener,
      data,
      [{:next_event, :internal, :initialize_listener}]
    }
  end

  def handle_event(:internal, :initialize_listener, state, data) do
    {:ok, listen_socket} =
      :gen_tcp.listen(
        data[:port],
        [:binary, {:packet, 0}, {:active, false}]
      )

    Logger.debug("TCP listener started on port: #{data[:port]}")

    data = Map.put(data, :listen_socket, listen_socket)

    handle_event(:internal, :accepting, state, data)
  end

  def handle_event(:internal, :accepting, state, data) do
    {:ok, accept_socket} = :gen_tcp.accept(data[:listen_socket])
    {:ok, {ip, port}} = :inet.sockname(accept_socket)
    ip = :inet.ntoa(ip) |> to_string
    Logger.debug("Accepted TCP connection: #{ip}:#{port} #{inspect(accept_socket)}")

    {:ok, child} =
      ConnectionSupervisor.start_child(%{accept_socket: accept_socket, ip: ip, port: port})

    # in order to receive messages via `:active`,
    # controlling process must be set
    :gen_tcp.controlling_process(accept_socket, child)

    # controlling process is set, so set tcp active
    Connection.set_tcp_active(child)

    handle_event(:internal, :accepting, state, data)
  end
end
