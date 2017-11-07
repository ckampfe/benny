defmodule DecoderTest do
  use ExUnit.Case
  doctest Benny
  alias Benny.Decoder
  require Decoder.DecodeError

  test "decodes ints" do
    assert Decoder.decode("i0e") == {0, ""}

    assert Decoder.decode("i40284024e") == {40284024, ""}

    assert Decoder.decode("i-9e") == {-9, ""}

    assert_raise Decoder.DecodeError, "cannot have -0", fn ->
      Decoder.decode("i-0e")
    end
    assert_raise Decoder.DecodeError, "cannot have leading 0", fn ->
      Decoder.decode("i03e") end
  end

  test "decodes strings" do
    assert Decoder.decode("3:cow") == {"cow", ""}
    assert Decoder.decode("7:willowyextra") == {"willowy", "extra"}
  end

  test "decodes dicts" do
    dict1 = "d3:cow3:moo4:spam4:eggse"
    assert Decoder.decode(dict1) == {%{"cow" => "moo", "spam" => "eggs"}, ""}

    dict2 = "d3:cow3:moo4:spam4:eggse;kajsdf;lsdf"
    assert Decoder.decode(dict2) == {%{"cow" => "moo", "spam" => "eggs"}, ";kajsdf;lsdf"}

    dict3 = "d3:cowd6:nested4:dicte4:spam4:eggsesomeextrainput"
    assert Decoder.decode(dict3) == {
      %{"cow" => %{"nested" => "dict"}, "spam" => "eggs"},
      "someextrainput"
    }
  end

  test "decodes lists" do
    list1 = "l5:chucke"
    assert Decoder.decode(list1) == {["chuck"], ""}

    list2 = "l5:chuck2:toe"
    assert Decoder.decode(list2) == {["chuck", "to"], ""}

    list3 = "l5:chuck2:tol3:sixei77ee"
    assert Decoder.decode(list3) == {["chuck", "to", ["six"], 77], ""}

    list4 = "l5:chuckd3:sam3:iamee"
    assert Decoder.decode(list4) == {["chuck", %{"sam" => "iam"}], ""}

    list5 = "l5:chuckd3:sam3:iameegarbage"
    assert Decoder.decode(list5) == {["chuck", %{"sam" => "iam"}], "garbage"}
  end

  test "decodes an example .torrent file" do
    torrent_file_data = File.read!("test/ubuntu-17.04-desktop-amd64.iso.torrent")
    assert {_result, ""} = Decoder.decode(torrent_file_data)
  end
end
