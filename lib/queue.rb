module IODemon
	class Queue
		include IODemon::Rack::Responses

		QUEUE_MAX_LENGTH = 50

		def initialize(channel, unique_hash, subscriber)			
			@channel_name = "#{channel}.#{unique_hash}"
			@subscriber = subscriber
			@unique_hash = unique_hash
			@redis = subscriber.queue_redis
			# puts "= " * 50			
			# puts "queue_redis: #{@redis.inspect}"
			# puts "channel_name: #{@channel_name.inspect}"
			# puts "unique_hash: #{@unique_hash.inspect}"			
			# puts "= " * 50
 			create_queue
		end		

		def add_message(message)			
			@redis.exist(@channel_name).callback do|exists_status|
				if exists_status == 1
					serialized_message = Marshal.dump({:message => message, :timestamp => Time.now.utc})
					@redis.rpush(@channel_name, serialized_message).callback {|msg_status|
						puts " #{msg_status} Message successfully added to user queue."
					}
				end
			end
		end

		def get_message
		end

		private

		def create_queue
			puts "= " * 50
			puts "-- Inside the queue creator --"
			puts "= " * 50 
		
		 @redis.exists(@channel_name).callback do |exists_status|
				if exists_status == 0
					puts "Exists Status == 0"
					init_message = Marshal.dump({:message => "inited", :timestamp => Time.now.utc})
					deferred_push = @redis.rpush(@channel_name, init_message)
					deferred_push.callback { |x| 
						puts "Message successfully added : #{x}"
						@subscriber.deferrable_response.append_message([@unique_hash])
						@subscriber.deferrable_response.succeed
						puts "*" * 50
						puts "Succeed called."
					}
					deferred_push.errback {|x|
						puts "Message could not be added : #{x}"
						EM.next_tick { raise x }
					}
				else
					puts "Subscriptions exists "
					@subscriber.deferrable_response.append_message([@unique_hash])
					@subscriber.deferrable_response.succeed
				end
			end.errback {|x|
				puts "ERROR REDIS EXISTS #{x.inspect}"
			}
			# @redis.exists(@channel_name).callback {|exists_status|
			# 	puts "exists_status : #{exists_status}"
			# 	if exists_status == 0
			# 		puts "Exists Status == 0"
			# 		init_message = Marshal.dump({:message => "inited", :timestamp => Time.now.utc})
			# 		deferred_response = @redis.rpush(@channel_name, init_message)
			# 		deferred_response.callback { |x| 
			# 			puts "message successfully added. #{x}"
			# 			@subscriber.deferrable_response.append_message([@unique_hash])
			# 			@subscriber.deferrable_response.succeed						
			# 		}
			# 		deferred_response.errback {|x| 
			# 			EM.next_tick do 
			# 				raise x
			# 			end
			# 		}
			# 	elsif exists_status == 1
			# 		puts "Subscription exists Exists Status == 0"
			# 		puts "- " * 50
			# 		@subscriber.deferrable_response.append_message([@unique_hash])
			# 	end
			# }

			# redis_exists_deferrable = @redis.exists(@channel_name)
			# redis_exists_deferrable.callback {|x| puts "Redis Exists #{x}"}
			# redis_exists_deferrable.errback {|x| puts "Redis exists No #{x}"}
		end
					
	end
end