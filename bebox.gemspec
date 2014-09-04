# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','bebox','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'bebox'
  s.version = Bebox::VERSION
  s.author = 'Codescrum'
  s.email = 'team@codescrum.com'
  s.homepage = 'http://www.codescrum.com'
  s.licenses    = ['MIT']
  s.platform = Gem::Platform::RUBY
  s.summary = 'Create basic provisioning of remote servers.'
  s.description = <<-EOF
    Bebox is a project born from the necessity of organizing a way to deal with the provisioning of remote servers.
    Bebox is based on puppet and much like another quite known project Boxen,
    the idea is to have a good agreement on how to manage a puppet repo for a remote environment.
    It is also a good idea to have a standard approach on dealing with the provisioning problem,
    including how to write modules, integrate them into the projects,
    a directory structure for the projects to follow,
    how to have a replicated 'development/test' environment into virtual machines, etc.
  EOF
  s.files = `git ls-files`.split("\n") - ['.ruby-version']
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.rdoc_options << '--title' << 'bebox' << '--main' << 'README.rdoc' << '--ri'
  s.bindir = 'bin'
  s.executables << 'bebox'
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency('rake', '10.3.1')
  s.add_development_dependency('aruba', '0.5.4')
  s.add_development_dependency('rspec', '2.14.1')
  s.add_development_dependency('jazz_hands', '0.5.2')
  s.add_development_dependency('serverspec', '1.6.0')
  s.add_development_dependency('factory_girl', '4.3.0')
  s.add_development_dependency('codeclimate-test-reporter', '0.4.0')
  s.add_development_dependency('simplecov', '0.9.0')
  s.add_runtime_dependency('gli','2.10.0')
  s.add_runtime_dependency('tilt', '2.0.1')
  s.add_runtime_dependency('highline', '1.6.21')
  s.add_runtime_dependency('progressbar', '0.21.0')
  s.add_runtime_dependency('colorize', '0.6.0')
end
