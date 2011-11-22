#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'herpes/extensions'
require 'herpes/workers'
require 'herpes/event'
require 'herpes/module'

class Herpes
	class Callback
		attr_reader :time, :block, :last

		def initialize (time, one_shot = false, &block)
			@time     = time
			@one_shot = one_shot
			@block    = block

			called!
		end

		def one_shot?
			@one_shot
		end

		def next_in
			time - (Time.now - last)
		end

		def call (*args, &block)
			block.call(*args, &block).tap { called! }
		end

		def called!
			@last = Time.now
		end
	end

	def self.load (*path)
		new.tap { |o| o.load(*path) }
	end

	def initialize
		@workers   = Workers.new
		@matchers  = Hash.new { |h, k| h[k] = [] }
		@modules   = []
		@callbacks = []
	end

	def load (*paths)
		paths.each {|path|
			instance_eval File.read(path), path, 1
		}
	end

	def use (name, &block)
		raise ArgumentError, "#{name} not found" unless Module[name]

		@modules << Module[name].use(self, &block)
	end

	def from (name, &block)
		return unless block

		@current = name
		instance_eval &block
		@current = nil
	end

	def on (matcher, &block)
		return unless block

		@matchers[@current] << Struct.new(:matcher, :block).new(matcher, block)
	end

	def dispatch (event)
		return unless event.is_a?(Event)

		@matchers.each {|name, matchers|
			next unless name.nil? || (event.respond_to?(:generated_by) && event.generated_by =~ name)

			dispatched = false

			matchers.each {|m|
				begin
					dispatched = true

					m.block.call(event)
				end if
					(m.matcher == :anything) ||
					(m.matcher == :anything_else && !dispatched) ||
					(m.matcher.respond_to?(:call) && m.matcher.call(event))
			}
		}
	end

	def every (time, &block)
		@callbacks << Callback.new(time, &block)

		wake_up
	end

	def after (time, &block)
		@callbacks << Callback.new(time, true, &block)

		wake_up
	end

	def until_next
		@callbacks.min_by &:next_in
	end

	def sleep (time)
		(@pipes ||= IO.pipe).first.read

		IO.select([@pipes.first], nil, nil, time)
	end

	def wake_up
		@pipes.last.write 'x'
	end

	def running?; !!@running; end
	def stopped?; !@running;  end

	def start!
		@running = true

		while running?
			@callbacks.select {|callback|
				callback.next_in <= 0
			}.each {|callback|
				callback.call

				@callbacks.delete(callback) if callback.one_shot?
			}

			sleep until_next
		end
	end

	def stop!
		@running = false;

		wake_up
	end
end
