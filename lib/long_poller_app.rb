module IODemon
	class LongPoller
		def initialize(redis)
			@redis = redis
		end

		def respond(env)
			@env = env
			@deferrable_response = IODemon::DeferrableResponse.new	
			request = ::Rack::Request.new(env)
			@channel = request.params['channel']
			@hash = request.params['h']			
			EM.next_tick {
				send_messages	
			}
			throw :async	
		end

		private 

		def send_messages
			EM.next_tick {
				@env['async.callback'].call([202, {'Content-Type'=>'application/json','Access-Control-Allow-Origin' => "*"}, @deferrable_response])
			}

			channel_name = "#{@channel}.#{hash}"
			IODemon::Queue.get_messages(@channel, @hash, @redis, @deferrable_response)	
		end
	end
end