defmodule HeadlineMaker do
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


  def main(argv) do
    {opts, _args, _invalid} =
      OptionParser.parse(argv,
        switches: [input: :string, output: :string, directory: :string, help: :boolean],
        aliases: [i: :input, o: :output, d: :directory, h: :help]
      )

    cond do
      opts[:help] ->
        print_help()

      # opts[:input] && opts[:output] ->
      opts[:input] ->
        input = opts[:input]
        output = opts[:output] || "NH00A000.BDY"
        directory = opts[:directory] || "."

        IO.puts("Input file: #{input}, Output files: #{output}, Directory: #{directory}")

        HeadlineWriter.write_headlines(input, output, directory)

      true ->
        IO.puts("Invalid options. Use --help for usage.")
    end
  end

  defp print_help do
    IO.puts("""
    Usage: headline_maker [options]

    Options:
      -i, --input   Input file
      -o, --output  Output file
      -h, --help    Show this help message
    """)
  end
end
