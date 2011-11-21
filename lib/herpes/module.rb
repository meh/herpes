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

class Module
	@modules = []

	def self.[] (name)
		return name if name.is_a?(Module)

		@modules.find {|mod|
			mod.name.downcase == name.downcase ||
			mod.aliases.any? { |ali| ali.downcase == name.downcase }
		}
	end
	
	def self.define (name, *aliases, &block)
		@modules << Module.new(name, *aliases, &block)
	end

	def initialize (name, *aliases, &block)
		@name    = name
		@aliases = aliases

		@matchers = []

		instance_eval &block
	end

	def on (*args, &block)
		@matchers << Struct.new(:arguments, :block).new(args, block)
	end

	def use (owner)
		@matchers.each {|matcher|
			owner.on *matcher.arguments, &matcher.block
		}
	end
end

end
