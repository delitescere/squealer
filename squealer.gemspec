# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{squealer}
  s.version = "2.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Josh Graham", "Durran Jordan"]
  s.date = %q{2010-05-20}
  s.description = %q{Exports mongodb to mysql. More later.}
  s.email = %q{joshua.graham@grahamis.com}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".gitignore",
     ".rvmrc",
     ".watchr",
     "README.md",
     "Rakefile",
     "VERSION",
     "lib/.example_squeal.rb.swp",
     "lib/example_squeal.rb",
     "lib/squealer.rb",
     "lib/squealer/boolean.rb",
     "lib/squealer/database.rb",
     "lib/squealer/hash.rb",
     "lib/squealer/object.rb",
     "lib/squealer/progress_bar.rb",
     "lib/squealer/target.rb",
     "lib/squealer/time.rb",
     "lib/tasks/jeweler.rake",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/squealer/boolean_spec.rb",
     "spec/squealer/database_spec.rb",
     "spec/squealer/hash_spec.rb",
     "spec/squealer/object_spec.rb",
     "spec/squealer/progress_bar_spec.rb",
     "spec/squealer/target_spec.rb",
     "spec/squealer/time_spec.rb",
     "squealer.gemspec"
  ]
  s.homepage = %q{http://github.com/delitescere/squealer/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Document-oriented to Relational database exporter}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/squealer/boolean_spec.rb",
     "spec/squealer/database_spec.rb",
     "spec/squealer/hash_spec.rb",
     "spec/squealer/object_spec.rb",
     "spec/squealer/progress_bar_spec.rb",
     "spec/squealer/target_spec.rb",
     "spec/squealer/time_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mysql>, [">= 2.8.1"])
      s.add_runtime_dependency(%q<mongo>, [">= 0.18.3"])
      s.add_runtime_dependency(%q<bson_ext>, [">= 1.0.1"])
    else
      s.add_dependency(%q<mysql>, [">= 2.8.1"])
      s.add_dependency(%q<mongo>, [">= 0.18.3"])
      s.add_dependency(%q<bson_ext>, [">= 1.0.1"])
    end
  else
    s.add_dependency(%q<mysql>, [">= 2.8.1"])
    s.add_dependency(%q<mongo>, [">= 0.18.3"])
    s.add_dependency(%q<bson_ext>, [">= 1.0.1"])
  end
end

