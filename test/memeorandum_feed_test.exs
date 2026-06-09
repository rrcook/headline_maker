defmodule MemeorandumFeedTest do
  use ExUnit.Case

  @valid_feed_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Memeorandum</title>
      <link>https://memeorandum.com</link>
      <item>
        <title>Test Article</title>
        <description><![CDATA[<p>Author Name</p><p>Test Headline &#x2014; Story text goes here</p>]]></description>
      </item>
    </channel>
  </rss>
  """

  describe "get_stories/3" do
    test "returns empty list for empty XML string" do
      assert MemeorandumFeed.get_stories(%{}, 5, "") == []
    end

    test "returns empty list for text that is not valid XML" do
      assert MemeorandumFeed.get_stories(%{}, 5, "not valid xml") == []
    end

    test "extracts headline and story from a valid feed" do
      result = MemeorandumFeed.get_stories(%{}, 5, @valid_feed_xml)
      assert result == [["Test Headline", "Story text goes here"]]
    end

    test "returns at most number_of_pages stories" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <description><![CDATA[<p>Author</p><p>Headline One &#x2014; Story one</p>]]></description>
          </item>
          <item>
            <description><![CDATA[<p>Author</p><p>Headline Two &#x2014; Story two</p>]]></description>
          </item>
        </channel>
      </rss>
      """
      result = MemeorandumFeed.get_stories(%{}, 1, xml)
      assert length(result) <= 1
    end

    test "filters out articles with ellipsis in the middle of the headline" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <description><![CDATA[<p>Author</p><p>Truncated...Headline &#x2014; Story text</p>]]></description>
          </item>
        </channel>
      </rss>
      """
      assert MemeorandumFeed.get_stories(%{}, 5, xml) == []
    end

    test "filters out articles with ellipsis in the middle of the story" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <description><![CDATA[<p>Author</p><p>Good Headline &#x2014; Story...continues here</p>]]></description>
          </item>
        </channel>
      </rss>
      """
      assert MemeorandumFeed.get_stories(%{}, 5, xml) == []
    end

    test "allows articles with ellipsis only at the end of the story" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <description><![CDATA[<p>Author</p><p>Good Headline &#x2014; Story text goes here...</p>]]></description>
          </item>
        </channel>
      </rss>
      """
      result = MemeorandumFeed.get_stories(%{}, 5, xml)
      assert length(result) == 1
    end

    test "filters out items with no emdash separator" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <description><![CDATA[<p>Author</p><p>Headline with no separator</p>]]></description>
          </item>
        </channel>
      </rss>
      """
      assert MemeorandumFeed.get_stories(%{}, 5, xml) == []
    end
  end

  describe "get_stories/2" do
    @tag :external
    test "returns empty list on invalid URL" do
      result = MemeorandumFeed.get_stories(%{input: "http://invalid.url"}, 5)
      assert result == []
    end
  end
end
