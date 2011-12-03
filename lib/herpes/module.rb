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

		Module.all.find { |mod| mod =~ name }
	end

	def self.define (name, *aliases, &block)
		Module.all << new(name, *aliases, &block)
	end

	extend Forwardable

	attr_reader    :name, :aliases, :owner
	def_delegators :owner, :state
	plain_accessor :check_every

	def initialize (name, *aliases, &block)
		@name    = name
		@aliases = aliases

		@before   = []
		@matchers = []
		@after    = []

		instance_eval &block
	end

	def method_missing (id, *args, &block)
		return owner.__send__ id, *args, &block if owner and owner.respond_to?(id)

		super
	end

	def owner= (value)
		@owner = value

		owned(value) if respond_to? :owned

		if respond_to? :check
			owner.every(check_every, self, &method(:check))
		end

		@before.each {|matcher|
			owner.before *matcher.arguments, &matcher.block
		}

		@matchers.each {|matcher|
			owner.on *matcher.arguments, &matcher.block
		}

		@after.each {|matcher|
			owner.after *matcher.arguments, &matcher.block
		}
	end

	def default (&block)
		block ? @default : @default = block
	end

	def with (&block)
		block = default unless block

		if !block
			raise ArgumentError, 'no block passed and a default is not present'
		end

		clone.tap { |o| o.instance_eval &block }
	end

	def use (owner, &block)
		with {
			self.owner = owner

			instance_eval &block
		}
	end

	def before (*args, &block)
		if owner = self.owner
			owner.from name do
				owner.before *args do |*args|
					owner.instance_exec *args, &block
				end
			end
		else
			@before << Struct.new(:arguments, :block).new(args, block)
		end
	end

	def on (*args, &block)
		if owner = self.owner
			owner.from name do
				owner.on *args do |*args|
					owner.instance_exec *args, &block
				end
			end
		else
			@matchers << Struct.new(:arguments, :block).new(args, block)
		end
	end

	def after (*args, &block)
		if owner = self.owner
			owner.from name do
				owner.after *args do |*args|
					owner.instance_exec *args, &block
				end
			end
		else
			@after << Struct.new(:arguments, :block).new(args, block)
		end
	end

	def dispatch (event = nil, &block)
		if block && !event
			event = Event.new(&block)
		end

		raise ArgumentError, 'you did not pass an Event' unless event.is_a?(Event)

		event.generated_by self

		owner.dispatch(event)
	end

	def =~ (other)
		return true if self == other

		name.to_s.downcase == other.to_s.downcase || aliases.any? { |a| a.to_s.downcase == other.to_s.downcase }
	end

	def inspect
		"#<#{self.class.name}(#{name}#{" [#{aliases.join ', '}]" unless aliases.empty?})>"
	end
end

end
