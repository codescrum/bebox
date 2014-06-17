# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','bebox','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'bebox'
  s.version = Bebox::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','bebox.rdoc']
  s.rdoc_options << '--title' << 'bebox' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'bebox'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.10.0')
  s.add_runtime_dependency('active_attr', '0.8.3')
  s.add_runtime_dependency('tilt', '2.0.1')
  s.add_runtime_dependency('highline', '1.6.21')
  s.add_runtime_dependency('progressbar', '0.21.0')
end
