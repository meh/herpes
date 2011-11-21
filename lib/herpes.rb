#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'herpes/workers'

class Herpes
	def self.load (path)

	end

	def initialize
		@workers  = Workers.new
		@matchers = []
		@modules  = []
	end

	def on (matcher, &block)
		return unless block

		@matchers << Struct.new(:matcher, :block).new(matcher, block)
	end

	def every (time, &block)

	end

	def after (time, &block)

	end

	def start!

	end
end
