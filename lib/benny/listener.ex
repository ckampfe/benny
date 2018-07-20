defmodule Benny.Listener do
  use GenStateMachine
  alias Benny.{Connection, ConnectionSupervisor}
  require Logger

  @accept_timeout 250

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(%{port_range: _port_range} = args) do
    Logger.debug("starting listener")
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
    port..max_port = data[:port_range]

    case :gen_tcp.listen(port, [:binary, {:packet, 0}, {:active, false}]) do
      {:ok, listen_socket} ->
        Logger.debug("TCP listener started on port: #{port}")

        data = Map.put(data, :listen_socket, listen_socket)

        handle_event(:internal, :accepting, state, data)

      {:error, reason} ->
        Logger.error("Tried to listen for TCP on port #{port}, got #{reason}")

        handle_event(
          :internal,
          :initialize_listener,
          state,
          Map.put(data, :port_range, Range.new(port + 1, max_port))
        )
    end
  end

  def handle_event(:internal, :accepting, state, data) do
    case :gen_tcp.accept(data[:listen_socket], @accept_timeout) do
      {:ok, accept_socket} ->
        {:ok, {ip, port}} = :inet.sockname(accept_socket)
        ip = :inet.ntoa(ip) |> to_string
        Logger.debug("Accepted TCP connection: #{ip}:#{port} #{inspect(accept_socket)}")

        {:ok, child} =
          ConnectionSupervisor.start_child(%{accept_socket: accept_socket, ip: ip, port: port})

        Process.link(child)

        # in order to receive messages via `:active`,
        # controlling process must be set
        :gen_tcp.controlling_process(accept_socket, child)

        # controlling process is set, so set tcp active
        Connection.set_tcp_active(child)

        handle_event(:internal, :accepting, state, data)

      {:error, :timeout} ->
        handle_event(:internal, :accepting, state, data)
    end
  end
end
