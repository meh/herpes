every 5.seconds do
	dispatch {
		time Time.now
		
		comment time.to_i.to_s[-2].to_i.odd? ? 'O_O' : '^_^'
	}
end

on :anything do |event|
	puts "It is #{event.time} #{event.comment}"
end
