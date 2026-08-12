defmodule FoxCouncilFeed do
  # Copyright 2026, Ralph Richard Cook
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

  @moduledoc """
  A `NewsFeeds` implementation for the Fox Council news API.

  Unlike the XML-based feeds (see `MemeorandumFeed`), Fox Council is a
  two-step JSON API:

    1. A root feed (`https://api.foxcouncil.com/news/us.json`) that lists
       articles, each with an `"Id"`.
    2. A per-article endpoint that, given an id, returns the full article as
       JSON with `"Title"` and `"Content"` fields.

  `get_stories/2,3` fetches the root feed, takes the first
  `@number_of_feeds` article ids, fetches each article, and returns a list
  of `[headline, story]` pairs. Any failure to reach the network results in
  an empty list rather than a raised exception, so a bad feed never crashes
  the caller.
  """

  require Logger

  # Upper bound on how many articles we pull from the root feed in a single
  # run. The caller can ask for fewer via `number_of_pages`.
  @number_of_feeds 10

  # The root feed listing articles, and the pre/post fragments used to build
  # a per-article URL of the form "<pre><id><post>".
  @article_root_url "https://api.foxcouncil.com/news/us.json"
  @article_url_pre "https://api.foxcouncil.com/news/articles/"
  @article_url_post ".json"

  @behaviour NewsFeeds

  @doc """
  Given a news feed JSON in the Fox Council family, send back a list
  of lists, each item is [headline, story].
  If we can't get the JSON pulled down then return an empty list.
  The /2 version of this function tries to pull the JSON from the URL specified in options[:input],
  and if that fails it returns an empty list.
  The /3 version of this function takes the JSON as a string and parses it directly,
  which is useful for testing and debugging.
  """
  @spec get_stories(any(), integer()) :: list()

  def get_stories(options, number_of_pages) do
    try do
      # The only part that I think will fail, the rest is just string manipulation

      root_url = options[:input] || @article_root_url
      req_body = HTTPoison.get!(root_url).body
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

  @doc """
  Parses an already-fetched root-feed JSON string and returns the stories.

  Takes at most `min(@number_of_feeds, number_of_pages)` article ids from the
  root feed, fetches each article, and returns a list of `[headline, story]`
  pairs. Passing the JSON directly is useful for testing without hitting the
  network. An empty string yields `[]`, as does any decode/parse failure.
  """
  # An empty body (e.g. after a failed fetch) means there's nothing to parse.
  def get_stories(_options, _number_of_pages, ""), do: []

  def get_stories(_options, number_of_pages, json) do
    # Honor the caller's limit, but never fetch more than @number_of_feeds.
    number_of_catches = min(@number_of_feeds, number_of_pages)

    try do
      {:ok, feed} = Jason.decode(json)
      IO.inspect("parse successful")

      # The root feed only lists article ids; grab the first
      # number_of_catches of them.
      article_ids =
        Map.get(feed, "articles")
        |> Enum.map(fn article -> Map.get(article, "Id") end)
        |> Enum.take(number_of_catches)

      # Fetch each article by id and pull out its headline and story. Fox
      # Council already provides a clean Title and Content, so unlike the XML
      # feeds there's no HTML-to-text extraction or emdash splitting to do
      # here; we just normalize UTF characters for the downstream renderer.
      Enum.map(article_ids, fn id ->
        article_url = "#{@article_url_pre}#{id}#{@article_url_post}"
        Logger.info("Fetching article from #{id}")
        article_json = HTTPoison.get!(article_url).body
        {:ok, article} = Jason.decode(article_json)

        [
          NewsFeeds.replace_utf_chars(Map.get(article, "Title")),
          NewsFeeds.replace_utf_chars(Map.get(article, "Content"))
        ]
      end)
    catch
      :exit, e ->
        Logger.error("Exit error while parsing feed: #{inspect(e)}")
        []
    end
  end
end
