defmodule TrackerTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "decodes all compact peers lists" do
    # see http://www.bittorrent.org/beps/bep_0023.html

    check all peers <- list_of(peer()),
              peer_string = Enum.join(peers),
              peers_count = Enum.count(peers) do
      decoded_peers = Benny.Decoder.decode_compact_peers(peer_string)

      assert Enum.count(decoded_peers) == peers_count

      assert Enum.all?(
               decoded_peers,
               fn {{ip1, ip2, ip3, ip4}, port}
                  when is_integer(ip1) and is_integer(ip2) and is_integer(ip3) and is_integer(ip4) and
                         is_integer(port) ->
                 true
               end
             )
    end
  end

  def peer do
    map(
      list_of(byte(), length: 6),
      &:binary.list_to_bin/1
    )
  end
end
