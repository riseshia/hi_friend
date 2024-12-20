# frozen_string_literal: true

require_relative "lib/hi_friend/version"

Gem::Specification.new do |spec|
  spec.name = "hi_friend"
  spec.version = HiFriend::VERSION
  spec.authors = ["Shia"]
  spec.email = ["rise.shia@gmail.com"]

  spec.summary = "Type unsafe Ruby LSP server"
  spec.description = "Type unsafe Ruby LSP server"
  spec.homepage = "https://github.com/riseshia/hi_friend"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/riseshia/hi_friend"
  spec.metadata["changelog_uri"] = "https://github.com/riseshia/hi_friend/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ test/ .git .github .gitignore .rspec Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "logger", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
