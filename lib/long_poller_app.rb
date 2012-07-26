module IODemon
	class LongPoller
		def initialize(redis, queue_redis)
			@redis = redis
			@queue_redis = queue_redis
		end

		def respond(env)
			@env = env			
			request = ::Rack::Request.new(env)
			@channel = request.params['channel']
			@hash = request.params['h']			
			send_messages			
		end

		private 

		def send_messages
			@deferrable_response = IODemon::DeferrableResponse.new	

			EM.next_tick {
				@env['async.callback'].call([202, {'Content-Type'=>'application/json','Access-Control-Allow-Origin' => "*"}, @deferrable_response])
				channel_name = "#{@channel}.#{hash}"
				IODemon::Queue.get_messages(@channel, @hash, @redis, @queue_redis, @deferrable_response)	
			}

			throw :async	
		end
	end
end