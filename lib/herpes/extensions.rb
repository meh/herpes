#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'forwardable'
require 'threadpool'

class Numeric
	def seconds
		self
	end; alias second seconds

	def minutes
		self * 60
	end; alias minute minutes

	def hours
		self * 60.minutes
	end; alias hour hours

	def days
		self * 24.hours
	end; alias day days
end

class Object
	def plain_accessor (*names)
		names.each {|name|
			define_singleton_method name do |*args|
				if args.empty?
					instance_variable_get "@#{name}"
				else
					value = (args.length > 1) ? args : args.first

					if value.nil?
						remove_instance_variable "@#{name}"
					else
						instance_variable_set "@#{name}", value
					end
				end
			end

			define_singleton_method "#{name}?" do
				instance_variable_get "@#{name}"
			end

			define_singleton_method "#{name}!" do
				instance_variable_set "@#{name}", true
			end

			define_singleton_method "no_#{name}!" do
				instance_variable_set "@#{name}", false
			end
		}
	end
end

class Module
	def plain_accessor (*names)
		names.each {|name|
			define_method name do |*args|
				if args.empty?
					instance_variable_get "@#{name}"
				else
					value = (args.length > 1) ? args : args.first

					if value.nil?
						remove_instance_variable "@#{name}"
					else
						instance_variable_set "@#{name}", value
					end
				end
			end

			define_method "#{name}?" do
				instance_variable_get "@#{name}"
			end

			define_method "#{name}!" do
				instance_variable_set "@#{name}", true
			end

			define_method "no_#{name}!" do
				instance_variable_set "@#{name}", false
			end
		}
	end
end
