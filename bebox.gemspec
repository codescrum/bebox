# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','bebox','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'bebox'
  s.version = Bebox::VERSION
  s.author = 'Codescrum'
  s.email = 'team@codescrum.com'
  s.homepage = 'http://www.codescrum.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Create basic provisioning of remote servers.'
  s.files = `git ls-files`.split("\n") - ['.ruby-version']
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.rdoc_options << '--title' << 'bebox' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'bebox'
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency('rake')
  s.add_development_dependency('aruba')
  s.add_development_dependency('rspec', '2.14.1')
  s.add_development_dependency('jazz_hands', '0.5.2')
  s.add_development_dependency('serverspec', '1.6.0')
  s.add_development_dependency('factory_girl', '4.3.0')
  s.add_runtime_dependency('gli','2.10.0')
  s.add_runtime_dependency('active_attr', '0.8.3')
  s.add_runtime_dependency('tilt', '2.0.1')
  s.add_runtime_dependency('highline', '1.6.21')
  s.add_runtime_dependency('progressbar', '0.21.0')
  s.add_runtime_dependency('colorize', '0.6.0')
end
