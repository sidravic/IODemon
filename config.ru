require 'rubygems'
require 'rack'
require 'json'
require 'em-hiredis'
require 'active_support'
require 'active_support/inflector'
require 'active_support/all'
require './lib/rack/responses.rb'
require './lib/server.rb'
require './lib/long_poller_app.rb'
require './lib/hasher.rb'
require './lib/subscriber_app.rb'
require './lib/queue.rb'
require './lib/deferrable_response.rb'


run IODemon::Server.new