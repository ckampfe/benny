defmodule Benny.Connection do
  use GenStateMachine
  alias Benny.PeerSupervisor
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

  def start_link(args) do
    GenStateMachine.start_link(__MODULE__, args)
  end

  def init([port]) do
    data =
      %{port: port,
        listen_socket: nil,
        acceptor_loop: nil,
        sockets: MapSet.new()
      }

    {:ok, :initializing_listener, data, [{:next_event, :internal, :initialize_listen_socket}]}
  end

  def handle_event(:internal, :initialize_listen_socket, state, data) do
    Logger.debug("state: #{state}")

    {:ok, listen_socket} =
      :gen_tcp.listen(
        data[:port],
        [:binary, {:packet, 0}, {:active, true}]
      )

    Logger.debug("set up listen socket: #{inspect(listen_socket)}")

    {
      :next_state,
      :initializing_acceptor_loop,
      Map.put(data, :listen_socket, listen_socket),
      [{:next_event, :internal, :initialize_acceptor_loop}]
    }
  end

  def handle_event(:internal, :initialize_acceptor_loop, state, data) do
    Logger.debug("state: #{state}")
    # :gen_tcp.accept/1 is blocking,
    # so it must be called in another process,
    # which is why we use proc_lib below.
    # using raw proc_lib is not great, should figure out a way to supervise this,
    # but linking ensures a total failure if the acceptor dies for some reason,
    # which is good
    acceptor_loop = :proc_lib.spawn_link(__MODULE__, :acceptor_loop, [self(), data[:listen_socket]])

    {:next_state, :accepting, Map.put(data, :acceptor_loop, acceptor_loop)}
  end

  def acceptor_loop(from, listen_socket) when is_pid(from) and is_port(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    {:ok, child} = PeerSupervisor.start_child(socket)
    :gen_tcp.controlling_process(socket, child)
    send(from, {:tcp_accept, socket, child})
    acceptor_loop(from, listen_socket)
  end

  ### TCP handlers

  def handle_event(:info, {:tcp_accept, socket, child}, state, data) do
    Logger.debug("state: #{state}")
    Logger.debug("accepted new socket #{inspect(socket)} for #{inspect(child)}")
    {
      :keep_state,
      Map.update(data, :sockets, [], fn(sockets) -> MapSet.put(sockets, socket) end),
    }
  end
end