require 'digest'
require 'digest/md5'

module IODemon
	class Hasher
		def self.hashify
			time = Time.now.utc
			salt = "IODemon" + rand(1000000).to_s
			unhashed_string = "#{time}#{salt}"
			Digest::MD5.hexdigest(unhashed_string)
		end
	end
end

