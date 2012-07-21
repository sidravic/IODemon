module IODemon
	class DeferrableResponse
		include EventMachine::Deferrable

		def each(&blk)
			@callback = blk
		end

		def append_message(body_data)
			body_data.each do |data_chunk|
				if @callback.present?
					@callback.call(data_chunk)
				end
			end
		end
		
	end
end