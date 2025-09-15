defmodule MemeorandumFeedTest do
  use ExUnit.Case

  @moduletag :external

  test "get_stories returns empty list on invalid URL" do
    options = %{input: "http://invalid.url"}
    result = MemeorandumFeed.get_stories(options, 5)
    assert result == []
  end

  test "get_stories returns a list for valid input" do
    # Use a real feed or mock HTTPoison if you want to avoid network calls.
    options = %{input: "https://memeorandum.com/feed.xml"}
    result = MemeorandumFeed.get_stories(options, 2)
    assert is_list(result)
  end

  test "get_stories returns at most requested number of stories" do
    options = %{input: "https://memeorandum.com/feed.xml"}
    result = MemeorandumFeed.get_stories(options, 2)
    assert length(result) <= 2
  end
end
