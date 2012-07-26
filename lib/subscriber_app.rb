module IODemon
	class Subscriber
		include IODemon::Rack::Responses		
		attr_accessor :subcription, :deferrable_response, :redis, :queue_redis

		def initialize(redis, queue_redis)
			@redis = redis
			@queue_redis = queue_redis	
			puts "&" * 50
			puts "REDIS : #{@redis.object_id}"
			puts "QUEUE_REDIS: #{@queue_redis.object_id}"
			puts "&" * 50					
		end

		# env contains parameters
		# Accepts the environment variables, parses the headers
		# Identifies and subscribes to the channel and returns a 202 accepted
		# On successful subscription activate on message callbacks which should return a deferred respose Async.callback
		def respond(env)
			@env = env		
			@deferrable_response = IODemon::DeferrableResponse.new	
			request = ::Rack::Request.new(@env)			
			channel = request.params["channel"]
			# puts "*" * 50
			# puts "Channel: #{channel}"
			# puts "*" * 50
			return IODemon::Rack::Responses::NOT_ACCEPTABLE unless channel.present?
			unique_hash = IODemon::Hasher.hashify
			EM.next_tick{
				subscribe(channel, unique_hash)
				puts "== SENDING THROW ASYNC =="
			}
			throw :async
			#generate_response(:accepted, unique_hash)
		end

		private

		def subscribe(channel = "/home", unique_hash)
			puts "In subscribe..."
			EM.next_tick { 
					puts "Sending async callback.."
					@env['async.callback'].call([200, {'Content-Type' => 'text/plain', 'Access-Control-Allow-Origin' => "*"}, @deferrable_response])
			}
			
			channel_name = "#{channel}.*"
			subscription = @redis.psubscribe(channel_name)

			subscription.callback{ |x|
				#Success
				# Create a new class. Create a message queue
				puts "Subscription to #{channel} successful"
				
				IODemon::Queue.new(channel, unique_hash, self)
			}

			subscription.errback{|err| 
				puts "[ERROR] #{err}" 
				EM.next_tick { 
					puts "== Error Scenario :#{err.inspect} =="
					raise err 
				}
			}

			@redis.on(:pmessage) do |key, channel, message|
				# On message 
				# push the message into the appropriate queue
				puts "[SUBSCRIBE]: #{key} #{channel}: #{message}"
				IODemon::Queue.add_message("#{channel}.#{unique_hash}", message, queue_redis)
			end
		end
	end
end