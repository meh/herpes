require 'herpes/rss'
require 'herpes/email'

state '~/.herpes'

# load the RSS module
use :rss do
	check_every 2.minutes

	# register sankaku with the following tags for the generated herpes
	tag :anime, :manga, :japan, :nsfw do
		register 'http://www.sankakucomplex.com/feed/'
	end

	# register incomaemeglio in the blog group
	group :blog do
		register 'http://feeds.feedburner.com/incomaemeglio', :smeriglia
	end
end

from :rss do
	before do |event|
		require 'nokogiri'

		[event.title, event.description].each {|obj|
			class << obj
				def strip_html
					Nokogiri::HTML(self).search('//text()').text
				end
			end
		}

		class << event
			def render
				"#{title.strip_html} (#{link})\n\n" << description.strip_html.to_s
			end
		end
	end

	on -> e { e.tags.include?(:nsfw) } do |event|
		with :email do
			from    'rss-nsfw@herpes'
			to      'meh@paranoici.org'
			subject event.title.strip_html

			via :procmail

			send event.render
		end
	end

	on :anything_else do |event|
		with :email do
			from    'rss@herpes'
			to      'meh@paranoici.org'
			subject event.title.strip_html

			via :procmail

			send event.render
		end
	end
end
