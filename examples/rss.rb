# load the RSS module
use :rss do
	# register sankaku with the following tags for the generated events
	tag :anime, :manga, :japan, :nsfw do
		register 'http://www.sankakucomplex.com/feed/'
	end

	# register incomaemeglio in the blog group
	group :blog do
		register 'http://feeds.feedburner.com/incomaemeglio'
	end
end

on -> e { e.tags.include?(:nsfw) } do |event|
	with :email do
		from 'rss-nsfw@events'
		to   'meh@paranoici.org'
	end.send(event)
end

on :anything_else do |event|
	with :email do
		from 'rss@events'
		to   'meh@paranoici.org'
	end.send(event)
end
