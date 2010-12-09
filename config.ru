require 'rack-rewrite'
require 'toto'
require 'haml'

# -----------------------------------------
# Rack configuration
# -----------------------------------------
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end


# -----------------------------------------
# Set some sane encoding defaults
# -----------------------------------------
# Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8


# -----------------------------------------
# Rack Rewrite configuration
# -----------------------------------------
use Rack::Rewrite do
  # Issue 301 for legacy URLs
  r301 %r{^/blog/archive/xmldsig-in-the-net-framework(.*)}, '/2009/08/04/xmldsig-in-the-net-framework$1'
  
  #r301 %r{^/blog/archive/(.*)$}, '/$1'
  r301 %r{^/blog/archive/(.*)$}, '/'
  r301 '/blog/archive/', '/archives/'
  r301 '/blog/', '/'
end

# -----------------------------------------
# Create and configure a toto instance
# -----------------------------------------
toto = Toto::Server.new do
  set :url,       'http://thomasjo.heroku.com/'
  set :author,    'Thomas Johansen'
  set :title,     'THOMASJO'
  set :ext,       'md'
  set :markdown,  :smart
  set :disqus,    false
  set :date,      lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
  set :to_html,   lambda {|path, page, ctx| Haml::Engine.new(File.read("#{path}/#{page}.haml"), { :format => :html5, :ugly => true }).render(ctx) }
end

run toto
