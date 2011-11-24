#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'rss'
require 'open-uri'

Herpes::Generator.define :rss do
	plain_accessor :digest

	check_every 5.minutes

	@tags = []
	@rss  = []

	def tag (*tags, &block)
		@tags.push tags
		instance_eval &block
		@tags.pop
	end

	def group (group, &block)
		@group, tmp = group, @group
		instance_eval &block
		@group = tmp
	end

	def register (url)
		@rss << Struct.new(:url, :tags, :group).new(url, @tags.flatten, @group)
	end

	def check
		digest = [] if digest?

		@rss.each {|r|
			(state[:rss] ||= {})[r.url] ||= []

			RSS::Parser.parse(open(r.url).read, false).tap {|p|
				p.items.each {|item|
					next if state[:rss][r.url].member? [item.date, item.title]

					event = Herpes::Event.new {
						tags  r.tags
						group r.group

						title       item.title
						link        item.link
						description item.description
						date        item.date
					}

					if digest
						digest.push(event)
					else
						dispatch(event)
					end

					state[:rss][r.url].push [item.date, item.title]
				}

				state[:rss][r.url].reject! {|(date, title)|
					p.items.none? {|item|
						item.date == date && item.title == title
					}
				}
			}
		}

		if digest
			dispatch Herpes::Event.new {
				events digest

				def to_a
					events
				end
			}
		end
	end
end
