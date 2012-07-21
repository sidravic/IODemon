module IODemon
	class DeferrableResponse
		include EventMachine::Deferrable

		def each(&blk)
			@callback = blk
		end

		def append_message(body_data)
			body_data.each do |data_chunk|
				puts "[DATA CHUNK] #{data_chunk}"
				if @callback.present?
					puts "[CALLBACK]"
					@callback.call(data_chunk)
				end
			end
		end
		
	end
end