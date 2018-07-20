defmodule Benny.Decoder do
  @moduledoc """
  Documentation for Benny.
  """

  defmodule DecodeError do
    defexception [:message]

    def exception(value) do
      %DecodeError{message: value}
    end
  end

  defmodule DecoderState do
    def start_link() do
    end
  end

  def decode_torrent_file(file) do
    {data, ""} =
      file
      |> File.read!()
      |> decode

    update_in(data, ["info", "pieces"], &decode_pieces/1)
  end

  def decode(f) do
    do_decode(f, %{})
  end

  ## DISPATCH

  # helper "done" sigil for composite structures that are nondeterministic
  def do_decode("e" <> _rest, _state) do
    :done
  end

  ## DICTIONARY
  def do_decode("d" <> rest, _state) do
    dstream =
      do_decode(rest, "")
      |> Stream.iterate(fn
        {"peers" = val, next} ->
          {b, r} = do_decode(next, val)
          {decode_compact_peers(b), r}

        {"peers6" = val, next} ->
          {b, r} = do_decode(next, val)
          {decode_compact_peers6(b), r}

        {val, next} ->
          do_decode(next, val)
      end)
      |> Stream.take_while(fn
        :done -> false
        _anything_else -> true
      end)
      |> Stream.chunk_every(2)

    res =
      Enum.reduce(dstream, %{}, fn [{k, _z}, {v, remaining}], acc ->
        acc
        |> Map.put(k, v)
        |> Map.put(:rest, remaining)
      end)

    {_, without_e} = Map.get(res, :rest) |> advance

    {Map.delete(res, :rest), without_e}
  end

  ## LIST
  def do_decode("l" <> rest, _state) do
    dstream =
      rest
      |> do_decode("")
      |> Stream.iterate(fn {val, next} -> do_decode(next, val) end)
      |> Stream.take_while(fn
        :done -> false
        _anything_else -> true
      end)

    res =
      Enum.reduce(dstream, %{list: [], rest: ""}, fn {item, remaining}, acc ->
        acc
        |> Map.update!(:list, fn list -> [item | list] end)
        |> Map.put(:rest, remaining)
      end)

    {_, without_e} = Map.get(res, :rest) |> advance

    {Enum.reverse(res[:list]), without_e}
  end

  ## INTEGER
  def do_decode("i" <> rest, _state) do
    {int, <<"e", remaining::binary>>} = decode_number(rest)
    {int, remaining}
  end

  ## STRING
  def do_decode(rest, state) do
    decode_string(rest, state)
  end

  def decode_string(rest, _state) do
    {size, <<":", remaining::binary>>} = decode_number(rest)
    <<b::binary-size(size), r::binary>> = remaining
    {b, r}
  end

  def decode_number(s) do
    s
    |> advance
    |> do_decode_number("")
  end

  def do_decode_number({"0", <<"e", _remaining::binary>> = rest}, _result) do
    {0, rest}
  end

  # special case for when a dict key or value has zero-length, like "0:"
  def do_decode_number({"0", <<":", _remaining::binary>> = rest}, result) when result == "" do
    {0, rest}
  end

  def do_decode_number({"0", rest}, result) when result == "" do
    raise DecodeError, "cannot have leading 0"
    {0, rest}
  end

  def do_decode_number({"-", <<"0", _>>}, _result) do
    raise DecodeError, "cannot have -0"
  end

  def do_decode_number({"-", rest}, result) do
    {int, remaining} =
      rest
      |> advance
      |> do_decode_number(result)

    {int * -1, remaining}
  end

  def do_decode_number({char, rest}, result) do
    case Integer.parse(char) do
      :error ->
        {String.to_integer(result), char <> rest}

      {_i, _} ->
        do_decode_number(advance(rest), result <> char)
    end
  end

  # purely functional character advancer
  def advance(""), do: {"", ""}

  def advance(<<s::binary-size(1), rest::binary>>) do
    {s, rest}
  end

  def decode_pieces(pieces_string) do
    decode_pieces(pieces_string, [])
  end

  def decode_pieces("", pieces), do: pieces

  def decode_pieces(<<piece::binary-size(20), rest::binary()>>, pieces) do
    decode_pieces(rest, [piece | pieces])
  end

  def decode_compact_peers(peers_data) do
    decode_compact_peers(peers_data, [])
  end

  def decode_compact_peers("0:", peers), do: peers
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
        <<ip_byte_1::size(8), ip_byte_2::size(8), ip_byte_3::size(8), ip_byte_4::size(8),
          port::size(16), remaining::binary()>>
      ) do
    # size is in bits
    # so, IP is first 4 bytes,
    # port is last 2 bytes.
    {{{ip_byte_1, ip_byte_2, ip_byte_3, ip_byte_4}, port}, remaining}
  end

  ########

  def decode_compact_peers6(peers_data) do
    decode_compact_peers6(peers_data, [])
  end

  def decode_compact_peers6("0:", peers), do: peers
  def decode_compact_peers6("", peers), do: peers

  def decode_compact_peers6(peers_data, peers) do
    # see http://www.bittorrent.org/beps/bep_0023.html
    # for what this is
    {peer, remaining} = decode_peer6(peers_data)

    decode_compact_peers6(
      remaining,
      [peer | peers]
    )
  end

  # haha
  def decode_peer6(
        <<ip_byte_1::size(8), ip_byte_2::size(8), ip_byte_3::size(8), ip_byte_4::size(8),
          ip_byte_5::size(8), ip_byte_6::size(8), ip_byte_7::size(8), ip_byte_8::size(8),
          ip_byte_9::size(8), ip_byte_10::size(8), ip_byte_11::size(8), ip_byte_12::size(8),
          ip_byte_13::size(8), ip_byte_14::size(8), ip_byte_15::size(8), ip_byte_16::size(8),
          port::size(16), remaining::binary()>>
      ) do
    # size is in bits
    # so, IP is first 4 bytes,
    # port is last 2 bytes.
    {{{
        ip_byte_1,
        ip_byte_2,
        ip_byte_3,
        ip_byte_4,
        ip_byte_5,
        ip_byte_6,
        ip_byte_7,
        ip_byte_8,
        ip_byte_9,
        ip_byte_10,
        ip_byte_11,
        ip_byte_12,
        ip_byte_13,
        ip_byte_14,
        ip_byte_15,
        ip_byte_16
      }, port}, remaining}
  end
end
