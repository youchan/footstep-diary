xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title 'あしあと日記'
    xml.description 'あしあと日記'
    xml.link 'http://blog.youchan.org'

    @entries.each do |entry|
      xml.item do
        xml.link "http://blog.youchan.org/#{entry[:date]}"
        xml.title entry[:title]
        xml.description entry[:description]
        xml.pubDate Time.parse(entry[:date]).rfc822()
        xml.guid "http://blog.youchan.org/#{entry[:date]}"
      end
    end
  end
end
