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

# this will be called on any event
on :anything do |event|
	# use email output
	use :email do
		to 'meh@paranoici.org'
	end.send(event)
end
