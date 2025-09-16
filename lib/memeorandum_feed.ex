defmodule MemeorandumFeed do
  # Copyright 2025, Ralph Richard Cook
  #
  # This file is part of Prodigy Reloaded.
  #
  # Prodigy Reloaded is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General
  # Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
  # option) any later version.
  #
  # Prodigy Reloaded is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
  # the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  # GNU Affero General Public License for more details.
  #
  # You should have received a copy of the GNU Affero General Public License along with Prodigy Reloaded. If not,
  # see <https://www.gnu.org/licenses/>.

  require Logger

  @number_of_feeds 10

  @utf_replace_map %{
    <<0xE2, 0x80, 0x98>> => "\'",
    <<0xE2, 0x80, 0x99>> => "\'",
    <<0xE2, 0x80, 0x9C>> => "\"",
    <<0xE2, 0x80, 0x9D>> => "\"",
    <<0xE2, 0x80, 0xA6>> => "..."
  }

  @behaviour NewsFeeds

  # Given a news feed XML in the memorandum family, send back a list
  # of lists, each item is [headline, story].
  # If we can't get the XML pulled down then return an empty list.
  @spec get_stories(any(), any()) :: list()
  def get_stories(options, number_of_pages) do
    try do
      # The only part that I think will fail, the rest is just string manipulation

      req_body = HTTPoison.get!(options[:input]).body
      IO.inspect("Got the body of #{options[:input]}")

      number_of_catches = min(@number_of_feeds, number_of_pages)

      # For our purposes we're just going to chop up the descriptions from the feed
      # 10 should be enough to get 4 good ones
      feed = Quinn.parse(req_body)
      IO.inspect("parse successful")

      article_summaries =
        Quinn.find(feed, [:item, :description])
        |> Enum.take(@number_of_feeds)
        |> Enum.map(fn x -> x.value end)
        |> Enum.map(&hd/1)

      # Take every string HTML and get the readable text out of it.
      # MOST of the time it's an author, then \n, then a headline and
      # next text separated by an emdash.
      # Sometimes there's not an emdash to split on so we filter out
      # lists that only have one element, then take 4 to pass back.
      Enum.map(article_summaries, fn s ->
        s
        |> Readability.article()
        |> Readability.readable_text()
        |> String.replace(Map.keys(@utf_replace_map), fn pat -> @utf_replace_map[pat] end)
        |> String.split("\n", parts: 2)
        |> Enum.at(1)
        # that's an emdash
        |> String.split("—", parts: 2)
        |> Enum.map(&String.trim/1)
      end)
      |> Enum.filter(fn l -> length(l) == 2 end)
      |> Enum.take(number_of_catches)
      |> Enum.map(fn article -> NewsFeeds.break_on_margin(article) end)
    rescue
      # If we can't get the request just return an empty list
      e ->
        IO.inspect("ruh roh")
        IO.inspect(e)
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        []
    end
  end
end
