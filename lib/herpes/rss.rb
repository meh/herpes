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

	def register (url, name = nil)
		@rss << Struct.new(:url, :name, :tags, :group).new(url, name, @tags.flatten, @group)
	end

	def check
		digest = [] if digest?

		@rss.each {|r|
			(state[:rss] ||= {})[r.url] ||= []

			RSS::Parser.parse(open(r.url).read, false).tap {|p|
				p.items.reverse_each {|item|
					if p.is_a?(RSS::Atom::Feed)
						next if state[:rss][r.url].member? [item.updated.content, item.title.content]
					else
						next if state[:rss][r.url].member? [item.date, item.title]
					end

					event = Herpes::Event.new {
						tags  r.tags
						group r.group
						name  r.name

						if p.is_a?(RSS::Atom::Feed)
							channel Struct.new(:title, :date, :link).new(p.title.content.dup, p.updated.content, p.link.href.dup)

							title       item.title.content.dup
							link        item.link.href.dup
							description item.content.content.dup
							date        item.updated.content
						else
							channel p.channel.dup

							title       item.title.dup
							link        item.link.dup
							description item.description.dup
							date        item.date
						end
					}

					if digest
						digest.push(event)
					else
						dispatch(event)
					end

					if p.is_a?(RSS::Atom::Feed)
						state[:rss][r.url].push [item.updated.content, item.title.content]
					else
						state[:rss][r.url].push [item.date, item.title]
					end
				}

				state[:rss][r.url].reject! {|(date, title)|
					p.items.none? {|item|
						if p.is_a?(RSS::Atom::Feed)
							 item.updated.content == date && item.title.content == title
						else
							item.date == date && item.title == title
						end
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
