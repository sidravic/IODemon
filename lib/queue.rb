module IODemon
	class Queue
		include IODemon::Rack::Responses

		QUEUE_MAX_LENGTH = 50

		def initialize(channel, unique_hash, subscriber =  nil)			
			@channel_name = "#{channel}.#{unique_hash}"
			@subscriber = subscriber
			@unique_hash = unique_hash
			@redis = subscriber.queue_redis
			# puts "= " * 50			
			# puts "queue_redis: #{@redis.inspect}"
			# puts "channel_name: #{@channel_name.inspect}"
			# puts "unique_hash: #{@unique_hash.inspect}"			
			# puts "= " * 50
 			create_private_queue
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

		def self.get_messages(channel, hash, redis_connection, deferred_rack_response)		
			message_array = []
			channel_name = "#{channel}.#{hash}"
			deferred_redis_response = redis_connection.llen(channel_name)
			deferred_redis_response.callback {|len|
				puts "Deferred Redis Response length: #{len}"
				if len > 0 															
					redis_connection.lrange(channel_name, 0, len -1).callback { |msgs|																		
						msgs.each {|m| message_array << Marshal.load(m).to_json}					
						0.upto(len -1) { 
							redis_connection.lpop(channel_name).callback {|elem|
								puts "Popped out read elements #{elem}"
							}.errback{|err|
								puts "[ERROR] #{err}"
							}
						}	
						puts "Messages #{message_array.inspect}"
						deferred_rack_response.append_message([message_array])	
						deferred_rack_response.succeed
						
					}	
				else					
					deferred_redis_psubscription = redis_connection.psubscribe("#{channel}.*")
					deferred_redis_psubscription.callback {
						redis_connection.on(:pmessage) do |key, channel, message|
							message = {:message => message, :timestamp => Time.now.utc}
							message_array.push(message)
							redis_connection.lpop.callback{|x|
								puts "Popping list #{x}"
							}							
							puts "Sending message back #{message_array.inspect}"
							deferred_rack_response.append_message([message_array.to_json])
							deferred_rack_response.succeed
							redis_connection.punsubscribe(channel_name).callback { |x|
								puts "Redis Connection Disconnected. #{x}"
							}
						end
					}

					redis_connection.errback{ |err|
						puts "[ERROR] #{err}"
					}
				end								
			}

		end

		private

		def create_private_queue
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