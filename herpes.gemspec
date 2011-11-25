Kernel.load 'lib/herpes/version.rb'

Gem::Specification.new {|s|
	s.name         = 'herpes'
	s.version      = Herpes.version
	s.author       = 'meh.'
	s.email        = 'meh@paranoici.org'
	s.homepage     = 'http://github.com/meh/herpes'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'A event/notification handler.'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_dependency 'threadpool'
}
