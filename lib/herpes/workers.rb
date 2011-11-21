#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'actionpool'

class Workers
	extend Forwardable

	def_delegators :@pool, :max, :max=, :min, :min=

	def initialize (range = 2 .. 4)
		@pool = ActionPool::Pool.new(:min_threads => range.begin, :max_threads => range.end)
	end

	def do (*args, &block)
		@pool.process(*args, &block)
	end
end

