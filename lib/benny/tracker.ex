defmodule Benny.Tracker do
  def announce(dot_torrent_data) do
    announce = dot_torrent_data["announce"]
    info_hash = info_hash(dot_torrent_data)

    params =
      %{
        info_hash: info_hash,
        peer_id: peer_id(),
        # optional, leave optional for now.
        # ip: nil,
        port: port(),
        uploaded: uploaded(),
        downloaded: downloaded(),
        left: left(dot_torrent_data),
        compact: compact()
        # optional, leave optional for now.
        # event:
      }

    query_params = URI.encode_query(params)
    response = HTTPoison.get!(announce <> "?" <> query_params)

    {decoded, ""} = Benny.Decoder.decode(response.body)
    decoded
  end

  def info_hash(dot_torrent_data) do
    info = dot_torrent_data["info"]
    bencoded = Benny.Encoder.encode(info)
    :crypto.hash(:sha, bencoded)
  end

  def peer_id do
    :crypto.strong_rand_bytes(20)
  end

  def port do
    6881
  end

  def uploaded do
    0
  end

  def downloaded do
    0
  end

  def left(dot_torrent_data) do
    dot_torrent_data["info"]["length"]
  end

  def compact do
    1
  end

  def decode_compact_peers(peers_data) do
    decode_compact_peers(peers_data, [])
  end

  def decode_compact_peers("", peers), do: peers
  def decode_compact_peers(peers_data, peers) do
    # see http://www.bittorrent.org/beps/bep_0023.html
    # for what this is
    {peer, remaining} = decode_peer(peers_data)

    decode_compact_peers(
      remaining,
      [peer | peers]
    )
  end

  def decode_peer(
    <<ip_byte_1 :: size(8),
      ip_byte_2 :: size(8),
      ip_byte_3 :: size(8),
      ip_byte_4 :: size(8),
      port :: size(16),
      remaining :: binary >>
  ) do
    # size is in bits
    # so, IP is first 4 bytes,
    # port is last 2 bytes.
    {{{ip_byte_1, ip_byte_2, ip_byte_3, ip_byte_4}, port}, remaining}
  end
end
