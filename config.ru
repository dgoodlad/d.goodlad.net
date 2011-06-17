require 'rack'
run Rack::File.new("output")
