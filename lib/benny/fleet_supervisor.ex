defmodule Benny.FleetSupervisor do
  @moduledoc """
  Supervisor a collection of torrents
  """

  use DynamicSupervisor

  ### CLIENT

  def add_torrent(torrent_path) do
    start_child(torrent_path)
  end

  ### SERVER

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(torrent_path) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Benny.TorrentSupervisor, %{torrent_path: torrent_path}}
    )
  end

  @impl true
  def init(_initial_arg) do
    DynamicSupervisor.init(
      # ,
      strategy: :one_for_one
      # extra_arguments: [initial_arg]
    )
  end
end
