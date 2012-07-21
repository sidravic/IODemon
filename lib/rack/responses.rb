 require 'active_support'
 require 'active_support/inflector'

 module IODemon
	module Rack
		module Responses			
			SUCCESS = [200,{"Content-Type" => "text/plain"}, ["200 OK"]]
			ACCEPTED = [202, {"Content-Type" => "text/plain"}, ["202 ACCEPTED"]]
			NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["404 NOT FOUND"]]			
			NOT_ACCEPTABLE = [406, {"Content-Type" => "text/plain"}, ["406 NOT ACCEPTABLE"]]
			

			def generate_response(response_type = :success, body = "")
				response = ("IODemon::Rack::Responses::" + response_type.to_s.upcase).constantize				
				response[2] = body
				response
			end

		end
	end
end