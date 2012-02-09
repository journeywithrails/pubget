# coding: UTF-8

Gem::Specification.new do |s|
  # Meta data
  s.name              = "pubget_paths"
  # Be sure to tag the new version if you update (e.g. git tag -v0.0.2 -m 'version 0.0.2')
  s.version           = "0.0.1"
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Pubget"]
  s.email             = ["iconnor@pubget.com"]
  s.homepage          = "https://github.com/pubget/pubget_paths"
  s.summary           = "Pubget paths gem"
  s.description       = "Pubget paths"
  s.rubyforge_project = s.name

  # System requirements
  # Note: dependencies are handled by Bundler (see Gemfile)
  s.required_rubygems_version = ">= 1.3.6"
  
  # The list of files to be contained in the gem
  s.files      = `git ls-files`.split("\n")
  s.test_files = ['test/paths_test.rb']
end
