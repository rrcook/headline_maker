defmodule DebugFeed do
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

  # Get stories from debug files made by debugoutput in HeadlineWriter
  # Every file is named hmdebug_N where N is the page number
  @spec get_stories(any(), any()) :: list()
  def get_stories(options, _number_of_pages) do
    socket = nil
    try do

      debug_path = options[:debuginput]
      if (debug_path == nil) do
        Logger.error("Debug input path not specified")
        []
      else
        case File.ls(debug_path) do
          {:ok, files} ->
             file_count = Enum.count(files, fn f -> File.regular?(Path.join(debug_path, f)) and String.starts_with?(f, "hmdebug_") end)
            Enum.map(1..file_count, fn n ->
              debug_file = Path.join(debug_path, "hmdebug_#{n}")
              if (!File.exists?(debug_file)) do
                Logger.error("Debug input file #{debug_file} does not exist")
                nil
              else
                {:ok, body} = File.read(debug_file)
                [headline, story] = String.split(body, HeadlineWriter.debug_delimiter())
                [headline, story]
              end
            end)
          {:error, reason} ->
            Logger.error("Debug input path #{debug_path} does not exist: #{reason}")
            []
        end
      end



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
end
