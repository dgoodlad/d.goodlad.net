# A sample Guardfile
# More info at http://github.com/guard/guard#readme

guard 'bundler' do
  watch 'Gemfile'
end

guard 'nanoc' do
  watch '^config.yaml'
  watch '^compass-config.rb'
  watch '^Rules'
  watch '^lib/*.rb'
  watch '^layouts/*'
  watch '^content/*'
end

# vim:ft=ruby
