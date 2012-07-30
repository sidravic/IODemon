module IODemon
	class Queue
		include IODemon::Rack::Responses

		QUEUE_MAX_LENGTH = 50

		def initialize(channel, unique_hash, subscriber =  nil)			
			@channel_name = "#{channel}.#{unique_hash}"
			@subscriber = subscriber
			@unique_hash = unique_hash
			@redis = subscriber.queue_redis			
 			create_private_queue
		end		

		def self.add_message(channel_name, message, redis)	
			puts "[ADDING MESSAGE] #{channel_name} #{message}"					
			serialized_message = Marshal.dump({:message => message, :timestamp => Time.now.utc})
			redis.rpush(channel_name, serialized_message).callback {|msg_status|
				puts " #{msg_status} Message successfully added to user queue."
			}.errback {|x| puts "ERROR: #{x}"}
			
		end

		def self.get_messages(channel, hash, redis_connection, queue_redis, deferred_rack_response)		
			message_array = []
			channel_name = "#{channel}.#{hash}"
			deferred_redis_response = redis_connection.llen(channel_name)
			deferred_redis_response.callback {|len|
				puts "Deferred Redis Response length: #{len}"
				if len > 0 
					puts "*" * 50	
					puts "[QUEUE]"														
					puts "*" * 50
					redis_connection.lrange(channel_name, 0, len -1).callback { |msgs|																		
						msgs.each {|m| message_array << Marshal.load(m).to_json}					
						0.upto(len - 1) { 
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
					puts "-" * 50	
					puts "[STREAM]"														
					puts "-" * 50
					periodic_timer = EM.add_periodic_timer(1) do 
						deferred_queue_check = redis_connection.llen(channel_name)
						deferred_queue_check.callback {|length|
							if length > 0
								redis_connection.lrange(channel_name, 0, len -1).callback{|msgs|
									msgs.each {|m| message_array << Marshal.load(m).to_json}										
								}
								0.upto(length - 1)
								redis_connection.lpop(channel_name).callback {|elem|
									puts "Popped out read elements #{elem}"
								}.errback{|err|
									puts "[ERROR] #{err}"
								}

								deferred_rack_response.append(message_array)
								deferred_rack_response.succeed
								periodic_timer.cancel
							end
						}
					end							

					EM.add_timer(20){ puts "Closing connection"; 
						deferred_rack_response.succeed 
						periodic_timer.cancel if !periodic_timer.nil?
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
		end
					
	end
end