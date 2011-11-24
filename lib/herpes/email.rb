#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'pony'

Herpes::Notifier.define :email, :mail do
	@options = %w(from to cc bcc sender subject headers charset text_part_charset message_id via via_options attachments)

	plain_accessor *@options

	@attachments = {}

	def via (name, options = {})
		if name == :procmail
			procmail = `which procmail`.chomp
			procmail = procmail.empty? ? '/usr/bin/procmail' : procmail

			via :sendmail, location: "#{options[:location] || procmail} -f #{from} #"
		else
			@via         = name
			@via_options = options
		end
	end

	def attachment (name, path)
		@attachments[name] = File.read(File.expand_path(path))
	end

	def to_hash
		result = {}

		@options.each {|name|
			result[name.to_sym] = instance_variable_get("@#{name}") if instance_variable_get("@#{name}")
		}

		result
	end

	def send (data)
		if !data.is_a?(Hash)
			data = { :text => data.to_s }
		end

		Pony.mail(to_hash.merge(body: data[:text], html_body: data[:html]))
	end
end
