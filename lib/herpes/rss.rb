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

Herpes::Module.define :rss do
	plain_accessor :digest

	check_every 5.minutes

	@tags = []
	@rss  = []

	def tag (*tags, &block)
		@tags.push tags
		result = instance_eval &block
		@tags.pop

		result
	end

	def group (group, &block)
		@group, tmp = group, @group
		result = instance_eval &block
		@group = tmp

		result
	end

	def register (url, name = nil)
		@rss << Struct.new(:url, :name, :tags, :group).new(url, name, @tags.flatten, @group)
		@rss.uniq!

		self
	end

	def check
		digest = [] if digest?

		@rss.each {|r|
			(state[:rss] ||= {})[r.url] ||= []

			content = begin
				open(r.url).read
			rescue Exception; end or next

			RSS::Parser.parse(content, false).tap {|p|
				p.items.reverse_each {|item|
					next if state[:rss][r.url].member?(if p.is_a?(RSS::Atom::Feed)
						item.link.href
					else
						item.link
					end)

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

					state[:rss][r.url].push(if p.is_a?(RSS::Atom::Feed)
						item.link.href
					else
						item.link
					end)
				}

				state[:rss][r.url].reject! {|link|
					p.items.none? {|item|
						link == if p.is_a?(RSS::Atom::Feed)
							item.link.href
						else
							item.link
						end
					}
				}
			} rescue warn $!
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
