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


  def decode_file(file) do
    {data, ""} =
      file
      |> File.read!
      |> decode

    update_in(data, ["info", "pieces"], &decode_pieces/1)
  end

  def decode(f) do
    do_decode(f, %{})
  end

  ## DISPATCH

  # helper "done" sigil for composite structures that are nondeterministic
  def do_decode("e" <> rest, state) do
    :done
  end

  ## DICTIONARY
  def do_decode("d" <> rest, state) do
    dstream =
      rest
      |> do_decode("")
      |> Stream.iterate(fn({val, next}) -> do_decode(next, val) end)
      |> Stream.take_while(fn
        :done -> false
        anything_else -> true
      end)
      |> Stream.chunk_every(2)

      res =
        Enum.reduce(dstream, %{}, fn([{k, z} = a, {v, remaining} = b], acc) ->
          acc
          |> Map.put(k, v)
          |> Map.put(:rest, remaining)
        end)

      {_, without_e} = Map.get(res, :rest) |> advance

      {Map.delete(res, :rest), without_e}
  end

  ## LIST
  def do_decode("l" <> rest, state) do
    dstream =
      rest
      |> do_decode("")
      |> Stream.iterate(fn({val, next}) -> do_decode(next, val) end)
      |> Stream.take_while(fn
        :done -> false
        anything_else -> true
      end)

      res =
        Enum.reduce(dstream, %{list: [], rest: ""}, fn({item, remaining}, acc) ->
          acc
          |> Map.update!(:list, fn(list) -> [item | list] end)
          |> Map.put(:rest, remaining)
        end)

      {_, without_e} = Map.get(res, :rest) |> advance

      {Enum.reverse(res[:list]), without_e}
  end

  ## INTEGER
  def do_decode("i" <> rest, state) do
    {int, <<"e", remaining :: binary>>} = decode_number(rest)
    {int, remaining}
  end

  ## STRING
  def do_decode(rest, state) do
    decode_string(rest, state)
  end

  def decode_string(rest, state) do
    {size, <<":", remaining :: binary >>} = decode_number(rest)
    << b :: binary-size(size), r :: binary >> = remaining
    {b, r}
  end

  def decode_number(s) do
    s
    |> advance
    |> do_decode_number("")
  end

  def do_decode_number({"0", <<"e", _remaining :: binary>> = rest}, result) do
    {0, rest}
  end
  def do_decode_number({"0", rest}, result) when result == "" do
    raise DecodeError, "cannot have leading 0"
  end
  def do_decode_number({"-", <<"0", _ >>}, result) do
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
      {i, _} ->
        do_decode_number(advance(rest), result <> char)
    end
  end

  # purely functional character advancer
  def advance(""), do: {"", ""}
  def advance(<< s :: binary-size(1), rest :: binary>>) do
    {s, rest}
  end

  def decode_pieces(pieces_string) do
    decode_pieces(pieces_string, [])
  end

  def decode_pieces("", pieces), do: pieces
  def decode_pieces(<<piece :: binary-size(20), rest :: binary()>>, pieces) do
    decode_pieces(rest, [piece | pieces])
  end
end
