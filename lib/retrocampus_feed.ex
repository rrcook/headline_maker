defmodule RetroCampusFeed do
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

  @behaviour NewsFeeds

  # Given a news feed XML in the memorandum family, send back an array
  # of tuples, each item is {headline, story}.
  # If we can't get the XML pulled down then return an empty array.
  @spec get_stories(any(), any()) :: list()
  def get_stories(options, _number_of_pages) do
    socket = nil
    try do
      retroguide = options[:retroguide]
      input = options[:input]

      # Use a charlist for pattern matching
      retroguide_charlist = String.to_charlist(retroguide)

      {:ok, s} = TelnetClient.open(input)
      socket = s

      # Toss the initial login prompt
      {:ok, throwaway} = TelnetClient.receive(socket, 5000)
      Logger.info("Received initial prompt, length is #{String.length(throwaway)}")

      raw_stories = gather_stories(retroguide_charlist, false, socket, [])

      TelnetClient.close(socket)
      Enum.map(raw_stories, fn rs -> carve_story(rs) end)
      |> Enum.map(fn article -> NewsFeeds.break_on_margin(article) end)

    rescue
      # If we can't get the request just return an empty list
      e ->
        IO.inspect("ruh roh")
        IO.inspect(e)
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        if socket != nil do
          TelnetClient.close(socket)
        end
        []
    end
  end

  # When we hit the dash we start gathering stories
  def gather_stories([?- | tail], _gathering, socket, acc) do
    gather_stories(tail, true, socket, acc)
  end

  def gather_stories([], _gathering, _socket, acc), do: Enum.reverse(acc)

  # Not gathering a story, don't add to the accumulator
  def gather_stories([ch | t], false, socket, acc) do
    TelnetClient.send(socket, <<ch, 13>>)
    {:ok, throwaway} = TelnetClient.receive(socket)
    Logger.info("Sent #{<<ch>>}, Received throwaway, length is #{String.length(throwaway)}")
    gather_stories(t, false, socket, acc)
  end

  # Gathering a story, add to the accumulator and toss the menu when we go back up
  def gather_stories([ch | t], true, socket, acc) do
    Logger.info("Gathering story character #{<<ch>>}")
    TelnetClient.send(socket, <<ch, 13>>)
    {:ok, buffer} = TelnetClient.receive(socket)
    Logger.info("Sent #{<<ch>>}, Received #{String.length(buffer)} bytes")

    TelnetClient.send(socket, ".")
    {:ok, _} = TelnetClient.receive(socket)

    gather_stories(t, true, socket, [buffer | acc])
  end

  # Carve out the headline and story from the raw text
  def carve_story(raw_story) do
    one_line = String.replace(raw_story, ~r/\r\n/, " ")
    start = Regex.split(~r/  /, String.trim_leading(one_line), parts: 2) |> Enum.at(1)
    [headline, raw_body] = Regex.split(~r/-------------------------------------------------------------------------------/, start, parts: 2)
    line_1 = Regex.split(~r/ /, String.trim_leading(raw_body), parts: 3)
    paragraph_1 = Regex.split(~r/  /, Enum.at(line_1, 2), parts: 2) |> Enum.at(0)
    [headline, paragraph_1]
  end
end
