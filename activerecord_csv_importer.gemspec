# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord_csv_importer/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord_csv_importer'
  spec.version       = ActiveRecordCSVImporter::VERSION
  spec.authors       = ['Zulfiqar Ali']
  spec.email         = ['desheikh@gmail.com']

  spec.summary       = 'A modified version of CSV Import using activerecord-import'
  spec.homepage      = 'https://github.com/desheikh/activerecord_csv_importer'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'virtus'
  spec.add_dependency 'activerecord-import'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.5'

  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop'

  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
end
