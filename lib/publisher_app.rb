# module IODemon
# 	class Publisher
# 		include IODemon::Rack::Responses

# 		def initialize(redis)
# 			@env = env
# 			@redis = redis
# 		end

# 		def respond(env)
# 			@env = env
# 			request = ::Rack::Request.new(@env)			
# 			@channel = request.params["channel"]
# 			@message = request.params["message"]
# 			if channel.present? && request.request_method.upcase == 'POST'
# 				publish_message
# 			else
# 				generate_response(:unauthorized)
# 			end
# 		end


# 		private 

# 		def publish_message
# 			if @message.present?
# 				channel_name = "#{@channel}.1"
# 				@redis.publish(channel_name, @message)
# 			end
# 		end
# 	end
# end