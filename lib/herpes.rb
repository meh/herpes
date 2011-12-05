#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'herpes/version'
require 'herpes/extensions'
require 'herpes/event'
require 'herpes/module'

class Herpes
	class Callback
		attr_reader :time, :discriminator, :block, :last

		def initialize (time, discriminator, one_shot = false, &block)
			raise ArgumentError, 'no block has been passed' unless block

			@time          = time
			@discriminator = discriminator
			@one_shot      = one_shot
			@block         = block

			if !one_shot?
				@last = Time.now - time
			else
				called!
			end
		end

		def one_shot?
			@one_shot
		end

		def next_in
			time - (Time.now - last)
		end

		def gonna_call!
			return if calling?

			@calling = :gonna
		end

		def gonna_call?
			@calling == :gonna
		end

		def calling!
			@calling = true
		end

		def called!
			@last    = Time.now
			@calling = false
		end

		def calling?
			@calling == true
		end

		def call (herpes, &block)
			return if calling?

			calling!
			@block.call(&block)
		ensure
			called!
			herpes.wake_up
		end
	end

	def self.load (*path)
		new.load(*path)
	end

	include Awakenable
	extend Forwardable

	attr_reader    :modules
	def_delegators :@pool, :do, :process

	def initialize
		@pool    = ThreadPool.new
		@modules = []

		@before   = Hash.new { |h, k| h[k] = [] }
		@matchers = Hash.new { |h, k| h[k] = [] }
		@after    = Hash.new { |h, k| h[k] = [] }

		@callbacks = []
	end

	def workers (number)
		@pool.resize(number)
	end

	def state (path = nil)
		if path && path != @path
			@path  = File.expand_path(path)
			@state = Marshal.load(File.read(@path)) rescue nil
		else
			@state ||= {}
		end
	end

	def save_every (time)
		cancel { |c| c.discriminator == self }

		every time, self do save end
	end

	def save
		return unless @state && @path

		Marshal.dump(@state).tap {|dump|
			File.open(@path, 'wb') { |f| f.write(dump) }
		}

		self
	end

	def load (*paths)
		paths.each {|path|
			instance_eval File.read(path), path, 1
		}

		self
	end

	def with (name, &block)
		raise ArgumentError, "#{name} not found" unless Module[name]

		Module[name].with(&block)
	end

	def use (name, &block)
		raise ArgumentError, "#{name} not found" unless Module[name]

		@modules << Module[name].use(self, &block)
	end

	def from (name, &block)
		return unless block

		@current, tmp = name, @current
		result = instance_eval &block
		@current = tmp
		result
	end

	def before (&block)
		return unless block

		@before[@current] << block
		@before[@current].uniq!

		self
	end

	def on (matcher, &block)
		return unless block

		@matchers[@current] << Struct.new(:matcher, :block).new(matcher, block)
		@matchers[@current].uniq!

		self
	end

	def after (&block)
		return unless block

		@after[@current] << block
		@after[@current].uniq!

		self
	end

	def dispatch (event = nil, &block)
		if block && !event
			event = Event.new(&block)
		end

		raise ArgumentError, 'you did not pass an Event' unless event.is_a?(Event)

		@before.each {|name, blocks|
			next unless name.nil? || (event.generated_by && event.generated_by =~ name)

			blocks.each { |b| b.call(event) }
		}

		@matchers.each {|name, matchers|
			next unless name.nil? || (event.generated_by && event.generated_by =~ name)

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

		@after.each {|name, blocks|
			next unless name.nil? || (event.generated_by && event.generated_by =~ name)

			blocks.each { |b| b.call(event) }
		}
	end

	def every (time, discriminator = nil, &block)
		@callbacks << Callback.new(time, discriminator, &block)
		wake_up
	end

	def once (time, discriminator = nil, &block)
		@callbacks << Callback.new(time, discriminator, true, &block)
		wake_up
	end; alias once_after once

	def cancel (&block)
		@callbacks.reject!(&block)
		wake_up
	end

	def until_next
		callbacks = @callbacks.reject(&:calling?).reject(&:gonna_call?)

		return if callbacks.empty?

		next_in = callbacks.min_by(&:next_in).next_in

		next_in > 0 ? next_in : 0
	end

	def running?; @running; end
	def stopped?; @stopped; end

	def start
		@running = true

		while running?
			sleep until_next or break

			@callbacks.select {|callback|
				callback.next_in <= 0 && !(callback.gonna_call? || callback.calling?)
			}.each {|callback|
				@callbacks.delete(callback) if callback.one_shot?

				callback.gonna_call!

				process {
					callback.call(self)
				}
			}
		end

		save

		@stopped = true
	end

	def stop!
		@running = false

		wake_up

		@pool.kill
	end

	def stop
		stop!

		sleep 0.01 until stopped?
	end
end
