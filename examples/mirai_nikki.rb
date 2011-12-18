# and this is another reason for making herpes, awesomely easy inlineable checkers
every 1.hour do
	state[:mirai_nikki_torrents] ||= []

	open('http://www.aozorateam.net/tracker/index/index.php').read.scan(%r((http://.*?%20Mirai%20Nikki%20-%20(\d+)%20.*\.mkv\.torrent))) {|uri, num|
		next if state[:mirai_nikki_torrents].member?(uri)

		state[:mirai_nikki_torrents].push(uri)

		with :email do
			via :procmail

			to      'herpes'
			from    'Mirai Nikki <rss@herpes>'
			subject "Episode #{num} available"

			send "Torrent: #{uri}"
		end
	}
end
