#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

class Herpes

class Event
	def initialize (&block)
		@data = {}
		
		instance_eval &block
	end

	def method_missing (id, *args)
		id = id.to_s.sub(/[=?]$/, '').to_sym

		if args.length == 0
			@data[id]
		else
			if respond_to? "#{id}="
				send "#{id}=", *args
			else
				value = (args.length > 1) ? args : args.first

				if value.nil?
					@data.delete(id)
				else
					@data[id] = value
				end
			end
		end
	end

	def to_hash
		@data.dup
	end
end

end
