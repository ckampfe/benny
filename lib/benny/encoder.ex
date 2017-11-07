defmodule Benny.Encoder do
  def encode(data) when is_map(data) do
    dict_data =
      data
      |> Map.keys
      |> Enum.sort
      |> Enum.reduce("", fn(key, acc) ->
        acc <> encode(key) <> encode(data[key])
      end)

    "d" <> dict_data <> "e"
  end

  def encode(data) when is_list(data) do
    list_data =
      Enum.reduce(data, "", fn(item, acc) ->
        acc <> encode(item)
      end)

    "l" <> list_data <> "e"
  end

  def encode(data) when is_integer(data) do
    "i" <> to_string(data) <> "e"
  end

  def encode(data) when is_binary(data) do
    to_string(byte_size(data)) <> ":" <> data
  end
end
