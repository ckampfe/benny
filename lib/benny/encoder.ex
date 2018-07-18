defmodule Benny.Encoder do
  def encode(data) when is_map(data) do
    sorted_keys =
      data
      |> Map.keys()
      |> Enum.sort()

    dict_data =
      sorted_keys
      |> Enum.reduce("", fn key, acc ->
        if key == "pieces" do
          s =
            Enum.reduce(data[key], fn piece, acc ->
              piece <> acc
            end)

          acc <> encode(key) <> encode(s)
        else
          acc <> encode(key) <> encode(data[key])
        end
      end)

    "d" <> dict_data <> "e"
  end

  def encode(data) when is_list(data) do
    list_data =
      Enum.reduce(data, "", fn item, acc ->
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
