defmodule NewsFeedsTest do
  use ExUnit.Case

  test "utf_replace_map returns expected map" do
    map = NewsFeeds.utf_replace_map()
    assert is_map(map)
    assert map[<<0xE2, 0x80, 0x98>>] == "'"
    assert map[<<0xE2, 0x80, 0x9C>>] == "\""
    assert map["é"] == "e"
  end

  test "replace_utf_chars replaces known UTF chars" do
    input = "“Hello…” ‘world’ é"
    expected = "\"Hello...\" 'world' e"
    assert NewsFeeds.replace_utf_chars(input) == expected
  end

  test "replace_utf_chars leaves unknown chars unchanged" do
    input = "abc Ω xyz"
    assert NewsFeeds.replace_utf_chars(input) == input
  end
end
