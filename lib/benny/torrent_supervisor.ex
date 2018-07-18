defmodule Benny.TorrentSupervisor do
  @moduledoc """
  Supervise the highpoint supervisor for an individual torrent
  Supervises a peer supervisor and a connection listener supervisor
  """
  alias Benny.PeerSupervisor

  use Supervisor

  def start_link(%{torrent_path: torrent_path} = initial_arg) do
    torrent_data = Benny.Decoder.decode_torrent_file(torrent_path)
    name = torrent_data["info"]["name"]

    Supervisor.start_link(
      __MODULE__,
      [initial_arg],
      name: {:via, Registry, {Benny.TorrentRegistry, "#{__MODULE__} - #{name}"}}
    )
  end

  def init(initial_arg) do
    IO.inspect(initial_arg, label: "INITIAL ARG")

    Supervisor.init(
      [
        {PeerSupervisor, []}
      ],
      strategy: :one_for_one
    )
  end
end
