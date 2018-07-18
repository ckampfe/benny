defmodule EncoderTest do
  use ExUnit.Case
  alias Benny.{Decoder, Encoder}
  doctest Encoder

  test "encodes ints" do
    assert Encoder.encode(0) == "i0e"

    assert Encoder.encode(40_284_024) == "i40284024e"

    assert Encoder.encode(-9) == "i-9e"
  end

  test "encodes strings" do
    assert Encoder.encode("cow") == "3:cow"

    assert Encoder.encode("willowy") == "7:willowy"
  end

  test "encodes lists" do
    assert Encoder.encode(["chuck"]) == "l5:chucke"
    assert Encoder.encode(["chuck", %{"sam" => "iam"}]) == "l5:chuckd3:sam3:iamee"
  end

  test "encodes dicts" do
    dict1 = "d3:cow3:moo4:spam4:eggse"
    data1 = %{"cow" => "moo", "spam" => "eggs"}
    assert Encoder.encode(data1) == dict1

    dict2 = "d4:spaml1:a1:bee"
    data2 = %{"spam" => ["a", "b"]}
    assert Encoder.encode(data2) == dict2
  end

  test "parses and encodes a file" do
    # load the raw bencoded torrent string for later comparison
    torrent_file_string = File.read!("test/ubuntu-17.04-desktop-amd64.iso.torrent")
    # load example torrent and parse it
    torrent_file_data = Decoder.decode_torrent_file("test/ubuntu-17.04-desktop-amd64.iso.torrent")

    # reencode it to bencode
    encoded_data = Encoder.encode(torrent_file_data)

    # is the reencoded version equal to the original?
    assert encoded_data == torrent_file_string
  end
end
