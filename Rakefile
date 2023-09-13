require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "haml-magic-translations"
    gem.summary = "Provides automaticaly translations in haml templates"
    gem.description = <<-DESCR
This plugin provides "magical translations" in your .haml files. What does it
mean? It's mean that all your raw texts in templates will be automatically
translated by GetText, FastGettext or Gettext backend from I18n. No more 
complicated translation keys and ugly translation methods in views. Now you can
only write in your language, nothing more. At the end of your work you can easy 
find all phrases to translate and generate .po files for it. This type of files 
are also more readable and easier to translate, thanks to it you save your 
time with translations.
    DESCR
    gem.email = "jardiniers@potager.org"
    gem.homepage = "http://github.com/potager/haml-magic-translations"
    gem.authors = ["Kriss Kowalik", "potager.org"]
    gem.add_dependency "haml", ">= 3.1.0"
    gem.add_development_dependency "actionpack"
    gem.add_development_dependency "gettext"
    gem.add_development_dependency "fast_gettext"
    gem.add_development_dependency "rspec", ">= 2"
    gem.add_development_dependency "rdoc", ">= 2.4.2"
    gem.add_development_dependency "maruku"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
require 'rdoc/task'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts  = %w(-fs --color)
end

namespace :spec do
  desc "Run all specs with RCov"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rspec_opts = ['--colour --format progress --loadby mtime --reverse']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec,/Users/']
  end
end

desc 'Generate documentation for the simple_navigation plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SimpleNavigation'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end
