defmodule Benny.Tracker do
  @doc """
  http://www.bittorrent.org/beps/bep_0048.html
  """
  def scrape(dot_torrent_data) do
    announce = dot_torrent_data["announce"]

    scrape = String.replace(announce, "announce", "scrape")

    info_hash = info_hash(dot_torrent_data)

    params = %{
      info_hash: info_hash
    }

    query_params = URI.encode_query(params)

    response = HTTPoison.get!(scrape <> "?" <> query_params)

    {decoded, ""} = Benny.Decoder.decode(response.body)
    decoded
  end

  @doc """
  http://www.bittorrent.org/beps/bep_0003.html
  """
  def announce(dot_torrent_data, event \\ :empty) do
    announce = dot_torrent_data["announce"]
    params = build_params(dot_torrent_data, event)

    query_params = URI.encode_query(params)

    response = HTTPoison.get!(announce <> "?" <> query_params)

    {decoded, ""} = Benny.Decoder.decode(response.body)
    decoded
  end

  def build_params(dot_torrent_data, event) do
    info_hash = info_hash(dot_torrent_data)

    params = %{
      info_hash: info_hash,
      peer_id: peer_id(),
      # optional, leave optional for now.
      # ip: :inet_parse.ntoa({162, 254, 168, 169}) |> to_string,
      port: port(),
      uploaded: uploaded(),
      downloaded: downloaded(),
      left: left(dot_torrent_data),
      compact: compact()
    }

    case event do
      :empty ->
        # leave it off, as this corresponds to a regular update
        params

      :started ->
        Map.put(params, :event, :started)

      :completed ->
        Map.put(params, :event, :completed)

      :stopped ->
        Map.put(params, :event, :stopped)
    end
  end

  def info_hash(dot_torrent_data) do
    info = dot_torrent_data["info"]
    bencoded = Benny.Encoder.encode(info)
    :crypto.hash(:sha, bencoded)
  end

  def peer_id do
    # :crypto.strong_rand_bytes(12)
    "-" <> "TR2940" <> "-" <> "123456789123"
  end

  def port do
    # 6881
    56000
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
end
