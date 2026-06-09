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
  @text_ellipsis "..."

  @behaviour NewsFeeds

  @doc """
  Given a news feed XML in the memorandum family, send back a list
  of lists, each item is [headline, story].
  If we can't get the XML pulled down then return an empty list.
  The /2 version of this function tries to pull the XML from the URL specified in options[:input],
  and if that fails it returns an empty list.
  The /3 version of this function takes the XML as a string and parses it directly,
  which is useful for testing and debugging.
  """
  @spec get_stories(any(), integer()) :: list()

  def get_stories(options, number_of_pages) do
    try do
      # The only part that I think will fail, the rest is just string manipulation

      req_body = HTTPoison.get!(options[:input]).body
      IO.inspect("Got the body of #{options[:input]}")
      get_stories(options, number_of_pages, req_body)
    rescue
      # If we can't get the request just return an empty list
      e ->
        IO.inspect("Problem getting feed from #{options[:input]}")
        IO.inspect(e)
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        get_stories(options, number_of_pages, "")
    end
  end

  def get_stories(_options, _number_of_pages, ""), do: []

  def get_stories(_options, number_of_pages, xml) do
    number_of_catches = min(@number_of_feeds, number_of_pages)

    # For our purposes we're just going to chop up the descriptions from the feed
    # 10 should be enough to get 4 good ones
    try do
      feed = Quinn.parse(xml)
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
        |> then(fn html -> Regex.replace(~r/<\/(p|div|article|h\d)/i, html, &"\n#{&1}") end)
        |> Floki.parse_document!()
        |> Floki.text()
        |> String.trim()
        |> NewsFeeds.replace_utf_chars()
        |> String.split("\n", parts: 2)
        |> Enum.at(1)
        # that's an emdash
        |> String.split("—", parts: 2)
        |> Enum.map(&String.trim/1)
        # Replace emdash with regular dash
        |> Enum.map(&String.replace(&1, "—", "-"))
      end)
      |> Enum.filter(fn l -> pass_article(l) end)
      |> Enum.take(number_of_catches)
    catch
      :exit, e ->
        Logger.error("Exit error while parsing feed: #{inspect(e)}")
        []
    end
  end

  defp contains_not_at_end?(text, pattern_text) do
    String.contains?(text, pattern_text) and not String.ends_with?(text, pattern_text)
  end

  defp pass_article(article) when length(article) != 2 do
    false
  end

  # We want to filter out articles that have ellipses in the middle of the headline or story, as that indicates
  # that the feed is truncating the text and we won't be able to summarize it properly.
  # If the ellipses are at the end of the text, that's probably just indicating that there's
  # more to the story, which is fine.
  defp pass_article([headline, story]) do
    cond do
      contains_not_at_end?(headline, @text_ellipsis) ->
        false

      contains_not_at_end?(story, @text_ellipsis) ->
        false

      true ->
        true
    end
  end
end
