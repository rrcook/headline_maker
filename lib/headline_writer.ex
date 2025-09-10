defmodule HeadlineWriter do
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
  use NaplpsConstants
  import NaplpsWriter

  @number_of_pages 4

  # TODO Add these constants to NaplpsConstants
  @text_width 6
  @text_height 10

  @gemini_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  @headline_length 60

  def write_headlines(options) do
    list_of_long_stories =
      options[:feedstyle].get_stories(options, @number_of_pages)

    list_of_stories = Enum.map(list_of_long_stories, fn [hl, body] ->
      short_hl = summarize_text(hl, @headline_length)
      [short_hl, body]
    end)

    list_of_pages = Enum.zip(1..length(list_of_stories), list_of_stories)

    [file, ext] = String.split(options[:output], ".", parts: 2)
    # First letter for the proper extension
    ext = String.slice(ext, 0, 1)

    # Write each page to a separate file
    Enum.each(list_of_pages, fn page ->
      # Make a page element object
      {page_number, _} = page
      peo = make_peo(options[:output], page, @number_of_pages)

      peo_buffer =
        ObjectEncoder.encode(peo)
        |> page_setup(page_number, @number_of_pages)

      file_path = Path.join(options[:directory], "#{file}.#{ext}_#{page_number}_8_1")
      File.write!(file_path, peo_buffer)
      Logger.info("Written story to #{file_path}")
    end)
  end

  def make_peo(output, {page_number, [headline, story]}, number_of_pages) do
    # Create a page element object with the headline and story

    [file, ext] = String.split(output, ".", parts: 2)
    file = ObjectUtils.edit_length(file, 8)
    ext = ObjectUtils.edit_length(ext, 3)

    pds = make_pds(page_number, headline, story, number_of_pages)

    Header.new(file, ext, :page_element_object, [pds])
  end

  # Make a presentation data segment (PDS) for the page
  def make_pds(page_number, headline, story, number_of_pages) do
    headline_naplps = make_headline_naplps(page_number, headline, story, number_of_pages)

    PresentationData.new(:presentation_data_naplps, headline_naplps)
  end

  def make_headline_naplps(page_number, headline, story, number_of_pages) do
    buffer =
      gcu_init()
      |> text_attributes({@text_width / 256, @text_height / 256})
      |> select_color(@color_gray)
      |> draw(@cmd_set_rect_outlined, [{0 / 256, 179 / 256}, {255 / 256, -1 * (179 - 51) / 256}])
      |> draw(@cmd_set_rect_outlined, [{1 / 256, 178 / 256}, {253 / 256, -1 * (178 - 52) / 256}])
      |> select_color(@color_black)
      |> draw(@cmd_set_rect_filled, [{2 / 256, 177 / 256}, {251 / 256, -1 * (178 - 53) / 256}])
      #    |> draw(@cmd_set_rect_outlined, [{2 / 256, 177 / 256}, {253 / 256, (-1 * (177 - 53)) / 256}])
      |> select_color(@color_gray)
      # |> draw_text_abs(String.slice(headline, 0..39), {4 / 256, 168 / 256})
      |> draw_text_abs(headline, {4 / 256, 168 / 256})
      |> select_color(@color_white)
      |> draw_text_abs(story, {4 / 256, 158 / 256})

    # If this is not a the last page, put up the [Next] button
    cond do
      page_number < number_of_pages ->
        select_color(buffer, @color_gray)
        |> draw_text_abs("Go to next page", {23 / 256, 55 / 256})
        |> draw_text_abs("[NEXT]", {222 / 256, 55 / 256})

      true ->
        buffer
    end
  end

  defp page_setup(buffer, page_number, total_pages) do
    <<
      buf1::binary-size(9),
      _extension1,
      _extension2,
      _orig_page_number,
      buf2::binary-size(3),
      orig_stage_flags,
      _orig_total_pages,
      rest::binary
    >> = buffer

    # the headline names in the object have the extension truncated to one letter
    # 8.3 -> 8.1 and two spaces
    <<
      buf1::binary-size(9),
      0x20,
      0x20,
      page_number,
      buf2::binary-size(3),
      orig_stage_flags,
      total_pages,
      rest::binary
    >>
  end

  def summarize_text(text, max_length) when is_binary(text) do
    api_key = System.get_env("GEMINI_API_KEY")

    try do
      post_body = """
      {
          "contents": [
            {
              "parts": [
                {
                  "text": "Summarize the text '#{text}' to #{max_length} characters "
                }
              ]
            }
          ]
      }
      """

      headers = [
        {"Content-Type", "application/json"},
        {"X-goog-api-key", api_key}
      ]

      {:ok, response_json} = HTTPoison.post(@gemini_url, post_body, headers)

      response_object = JSON.decode!(response_json.body)
      candidates_map = response_object["candidates"] |> Enum.at(0)
      text_map = candidates_map["content"]["parts"] |> Enum.at(0)
      text_map["text"]
    rescue
      e in RuntimeError ->
        Logger.error("Error summarizing text: #{e.message}")
        text
    end
  end
end
