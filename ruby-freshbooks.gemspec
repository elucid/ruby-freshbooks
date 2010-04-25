Gem::Specification.new do |s|
  s.name = %q{ruby-freshbooks}
  s.version = File.read(File.join(File.dirname(__FILE__),'VERSION')).chomp

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Justin Giancola"]
  s.date = %q{2010-04-25}
  s.description = %q{simple FreshBooks API wrapper}
  s.email = %q{elucid@gmail.com}
  s.files = ["README.md", "LICENSE", "VERSION", "ruby-freshbooks.gemspec", "lib/freshbooks.rb", "lib/ruby-freshbooks.rb", "spec/freshbooks_spec.rb"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/elucid/ruby-freshbooks}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = s.description

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0')
      s.add_runtime_dependency(%q<httparty>, [">= 0.5.0"])
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.0"])
    else
      s.add_dependency(%q<httparty>, [">= 0.5.0"])
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<rspec>, [">= 1.3.0"])
    end
  else
    s.add_dependency(%q<httparty>, [">= 0.5.0"])
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<rspec>, [">= 1.3.0"])
  end
end
