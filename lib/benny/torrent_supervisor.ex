defmodule Benny.TorrentSupervisor do
  @moduledoc """
  Supervise the highpoint supervisor for an individual torrent
  Supervises a peer supervisor and a connection listener supervisor
  """

  use Supervisor

  alias Benny.Torrent

  def start_link(%{torrent_path: torrent_path} = arg) do
    torrent_data = Benny.Decoder.decode_torrent_file(torrent_path)
    name = torrent_data["info"]["name"]

    arg = Map.put(arg, :torrent_data, torrent_data)

    Supervisor.start_link(
      __MODULE__,
      arg,
      name: {:via, Registry, {Benny.TorrentRegistry, "#{__MODULE__} - #{name}"}}
    )
  end

  def init(arg) do
    # IO.inspect(arg, label: "INITIAL ARG")

    # load torrent file
    # announce to tracker with "started" status and info in BEP003
    # set timer for tracker-provided refresh time
    # on that timer make announcement update with info in BEP003
    #
    # some process is storing state of:
    # - peerlist and peer status (chocked, interested, etc.)
    # - announce update timeout
    # - downloaded
    # - uploaded
    # - number of available connections

    Supervisor.init(
      [
        # {PeerSupervisor, []}
        {Torrent, arg}
      ],
      strategy: :one_for_one
    )
  end
end
