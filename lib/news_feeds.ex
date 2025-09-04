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

  # @margin 60
  @margin 45
  @newline "\r\n "

  @callback get_stories(options :: map(), number_of_pages :: non_neg_integer()) :: list(String.t())

  @spec break_on_margin([binary(), ...], any()) :: [binary(), ...]
  def break_on_margin([hl, body], margin \\ @margin) do
    hl_lines = break_text_on_margin(hl, margin)
    body_lines = break_text_on_margin(body, margin)
    [hl_lines, @newline <> body_lines]
  end

  defp break_text_on_margin(text, margin) do
    # current_line = []
    # Split the input text into words using regular expression
    words = String.split(text, ~r/\s+/u)

    {lines, current_line} =
      Enum.reduce(words, {[], []}, fn word, {lines, current_line} ->
        if length(current_line) == 0 do
          {lines, [word]}
        else
          line_length = String.length(Enum.join(current_line, " ")) + 1 + String.length(word)

          if line_length <= margin do
            {lines, current_line ++ [word]}
          else
            {lines ++ [Enum.join(current_line, " ")], [word]}
          end
        end
      end)

    if length(current_line) > 0 do
      Enum.join(lines ++ [Enum.join(current_line, " ")], @newline)
    else
      Enum.join(lines, @newline)
    end
  end
end
