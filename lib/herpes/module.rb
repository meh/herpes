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
	def_delegators :owner, :state, :workers

	def initialize (name, *aliases, &block)
		@name    = name
		@aliases = aliases

		instance_eval &block
	end

	def =~ (other)
		return true if self == other

		name.to_s.downcase == other.to_s.downcase || aliases.any? { |a| a.to_s.downcase == other.to_s.downcase }
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

	def use (*)
		raise NotImplementedError, 'you have to use a specialized module'
	end

	def inspect
		"#<#{self.class.name}(#{name}#{" [#{aliases.join ', '}]" unless aliases.empty?})>"
	end
end

class Generator < Module
	plain_accessor :check_every

	def initialize (*)
		super
	end

	def use (owner, &block)
		with(&block).tap {|o|
			o.instance_eval {
				@owner = owner

				owned if respond_to? :owned

				if respond_to? :check
					@owner.every(check_every, &method(:check))
				end
			}
		}
	end

	def dispatch (event = nil, &block)
		if block && !event
			event = Event.new(&block)
		end

		raise ArgumentError, 'you did not pass an Event' unless event.is_a?(Event)

		event.generated_by self

		owner.dispatch(event)
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

				owned if respond_to? :owned

				@matchers.each {|matcher|
					@owner.on *matcher.arguments, &matcher.block
				}
			}
		}
	end
end

end
