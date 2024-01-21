# frozen_string_literal: true

require_relative 'lib/inboxable/version'

Gem::Specification.new do |spec|
  spec.name = 'inboxable'
  spec.version = Inboxable::VERSION
  spec.authors = ['Muhammad Nawzad']
  spec.email = ['hama127n@gmail.com']

  spec.summary = 'An opiniated Gem for Rails applications to implement the transactional inbox pattern.'
  spec.description = 'An opiniated Gem for Rails applications to implement the transactional inbox pattern.'

  spec.homepage = 'https://github.com/muhammadnawzad/inboxable'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/muhammadnawzad/inboxable'
  spec.metadata['changelog_uri'] = 'https://github.com/muhammadnawzad/inboxable/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
