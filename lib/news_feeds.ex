defmodule NewsFeeds do
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

  @callback get_stories(options :: map(), number_of_pages :: non_neg_integer()) :: list(String.t())

    @utf_replace_map %{
    <<0xE2, 0x80, 0x98>> => "\'",
    <<0xE2, 0x80, 0x99>> => "\'",
    <<0xE2, 0x80, 0x9C>> => "\"",
    <<0xE2, 0x80, 0x9D>> => "\"",
    <<0xE2, 0x80, 0xA6>> => "...",
    #emdash to regular dash
    # "—" => "-",
    "é" => "e"
  }

  @utf_keys Map.keys(@utf_replace_map)

  @spec utf_replace_map() :: %{optional(<<_::16, _::_*8>>) => <<_::8, _::_*16>>}
  def utf_replace_map(), do: @utf_replace_map

  @spec replace_utf_chars(binary()) :: binary()
  def replace_utf_chars(text) do
    Logger.debug("Replacing UTF chars in #{text}")
    String.replace(text, @utf_keys, fn pat -> @utf_replace_map[pat] end)
  end

end
