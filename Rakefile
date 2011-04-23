task :default => :sass

desc "Convert the primary stylesheet from Sass CSS format to standard CSS."
task :sass do
  `sass --scss --no-cache --style compressed public/css/main.scss public/css/main.css`
end
