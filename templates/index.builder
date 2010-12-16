xml.instruct!
xml.feed :xmlns => 'http://www.w3.org/2005/Atom' do
  xml.id @config[:url]
  xml.title @config[:title]
  xml.link :rel => 'self', :href => 'http://feeds.feedburner.com/thomasjo'
  xml.updated articles.last[:date].strftime('%Y-%m-%dT%H:%M:%SZ') unless articles.empty?
  xml.author { xml.name @config[:author] }

  articles.reverse[0...10].each do |article|
    xml.entry do
      xml.title article.title
      xml.link :rel => 'alternate', :href => article.url
      xml.id article.url
      xml.published (article[:date]).strftime('%Y-%m-%dT%H:%M:%SZ')
      xml.updated article[:date].strftime('%Y-%m-%dT%H:%M:%SZ')
      xml.author { xml.name @config[:author] }
      xml.summary article.summary, :type => 'html'
      xml.content article.body, :type => 'html'
    end
  end
end

