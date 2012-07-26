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
			when "/publish"
				publisher.respond(env)
			else
				::Rack::Response.new("File Not Found", 404)
			end				
		end

		private

		def subscriber
			@subscriber ||= IODemon::Subscriber.new(redis_subscriber, queue_redis)
		end

		def long_poller			
			@long_poller ||= IODemon::LongPoller.new(redis_long_poller, poller_queue_redis)
		end

		def publisher
			@publisher ||= IODemon::LongPoller.new(redis_publisher)
		end

		def redis_publisher
			@redis_publisher ||= EM::Hiredis.connect
		end

		def redis_subscriber
			@redis_subscriber ||= EM::Hiredis.connect
		end

		def redis_long_poller
			@redis_long_poller ||= EM::Hiredis.connect
		end

		def queue_redis
			@queue_redis ||= EM::Hiredis.connect
		end

		def poller_queue_redis
			@poller_queue_redis ||= EM::Hiredis.connect
		end
	end
	
end