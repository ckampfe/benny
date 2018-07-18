defmodule Benny.Peer do
  def handshake do
    _nineteen = <<19>>
    _bt_proto = "BitTorrent protocol"
    _eight_reserved_bytes = <<0, 0, 0, 0, 0, 0, 0, 0>>
    _hashed_info_value = ""
    _peer_id = ""
  end
end
