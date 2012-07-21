require 'rack'

module IODemon
	class Server
		def call(env)
			@request = ::Rack::Request.new(env)

			case @request.path
			when "/"
				::Rack::Response.new('File Not Found', 404)
			when "/subscribe"
				subscriber.respond(env)
			when "/poll"
				long_poller.respond(env)
			else
				::Rack::Response.new("File Not Found", 404)
			end				
		end

		private

		def subscriber
			@subscriber ||= IODemon::Subscriber.new(redis_subscriber)
		end

		def long_poller			
			@long_poller ||= IODemon::LongPoller.new(redis_long_poller)
		end

		def redis_subscriber
			@redis_subscriber ||= EM::Hiredis.connect
		end

		def redis_long_poller
			@redis_long_poller ||= EM::Hiredis.connect
		end
	end
	
end