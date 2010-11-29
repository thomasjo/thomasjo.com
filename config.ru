require 'toto'
require 'haml'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

Encoding.default_internal = Encoding::UTF_8

#
# Create and configure a toto instance
#
toto = Toto::Server.new do
  #
  # Add your settings here
  # set [:setting], [value]
  #
  set :url,       'http://thomasjo.heroku.com/'
  set :author,    'Thomas Johansen'
  set :title,     'Thomas Johansen\'s Blog'
  set :ext,       'md'
  set :markdown,  :smart
  set :disqus,    false
  set :date,      lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
  set :to_html,   lambda {|path, page, ctx| Haml::Engine.new(File.read("#{path}/#{page}.html.haml"), { :format => :html5 }).render(ctx) }


  # set :root,      "index"                                   # page to load on /
  # set :date,      lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  # set :cache,     28800                                     # cache duration, in seconds
  # set :summary,   :max => 150, :delim => /~/                # length of article summary and delimiter
end

run toto
