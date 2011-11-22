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
	def self.all
		@modules ||= []
	end

	def self.[] (name)
		return name if name.is_a?(Module)

		Module.all.find {|mod|
			mod.name.downcase == name.downcase ||
			mod.aliases.any? { |ali| ali.downcase == name.downcase }
		}
	end

	def self.define (name, *aliases, &block)
		Module.all << new(name, *aliases, &block)
	end

	attr_reader :name, :aliases

	def initialize (name, *aliases, &block)
		@name    = name
		@aliases = aliases

		instance_eval &block
	end

	def default (&block)
		block ? @default : @default = block
	end

	def with (&block)
		block = default unless block

		if !block
			raise ArgumentError, 'no block passed and a default is not present'
		end

		dup.tap { |o| o.instance_eval &block }
	end

	def use (*)
		raise NotImplementedError, 'you have to use a specialized module'
	end
end

class Checker < Module
	plain_accessor :check_every

	def initialize (*)
		super
	end

	def check
		raise NotImplementedError, 'the module has not been specialized'
	end

	def use (owner, &block)
		with(&block).tap {|o|
			o.instance_eval {
				@owner = owner
				@owner.every(check_every, &method(:check))
			}
		}
	end
end

class Notifier < Module
	def initialize (*)
		@matchers = []

		super
	end

	def on (*args, &block)
		@matchers << Struct.new(:arguments, :block).new(args, block)
	end

	def use (owner, &block)
		with(&block).tap {|o|
			o.instance_eval {
				@owner = owner
				@matchers.each {|matcher|
					@owner.on *matcher.arguments, &matcher.block
				}
			}
		}
	end
end

end
