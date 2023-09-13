# -*- coding: UTF-8 -*-

require 'rake'
require 'rake/tasklib'
require 'gettext'
require 'gettext/tools'
require 'gettext/tools/rgettext'

require 'haml/magic_translations/rgettext/haml_parser'

module Haml::MagicTranslations::Tasks # :nodoc:
  # Rake task to generate and update PO files for a project using
  # Haml::MagicTranslations
  #
  # === Example
  #
  # Rakefile excerpt:
  #
  #   Haml::MagicTranslations::Tasks::UpdatePoFiles.new do |t|
  #     t.text_domain = 'my_project'
  #     t.files = Dir.glob("views/**/*.{rb,haml}") << "lib/my_project.rb"
  #     t.app_version = 'my_project 0.1'
  #   end
  #
  # Updating PO files in the ++po++ directory will be done by issuing:
  #
  #   rake update_pofiles
  #
  class UpdatePoFiles < ::Rake::TaskLib
    # The name of the task
    attr_accessor :name

    # the textdomain name (see GetText.update_pofiles)
    attr_accessor :text_domain

    # an Array of target files, that should be parsed for messages
    attr_accessor :files

    # the application information which appears "Project-Id-Version: #app_version" in the pot/po-files
    attr_accessor :app_version

    # update files only for one language - the language specified by this option
    attr_accessor :lang

    # the root directory of po-files
    attr_accessor :po_root

    # an array with the options, passed through to the gnu msgmerge tool
    #
    # Symbols are automatically translated to options with dashes,
    # example: ++[:no_wrap, :no_fuzzy_matching, :sort_output]++ translated to
    # ++--no-fuzzy-matching --sort-output++.
    attr_accessor :msgmerge

    # true to show verbose messages. default is false
    attr_accessor :verbose

    def initialize(name = :update_pofiles)
      @name = name

      yield self if block_given?

      define
    end

  protected

    def define
      desc "Update PO files"
      task(name) do
        [ :text_domain, :files, :app_version ].each do |opt|
          abort "`#{opt}` needs to be set." if send(opt).nil?
        end
        options = {}
        [ :lang, :po_root, :verbose ].each do |opt|
          options[opt] = send(opt) if send(opt)
        end
        GetText::RGetText.add_parser(Haml::MagicTranslations::RGetText::HamlParser)
        GetText.update_pofiles(text_domain, files, app_version, options)
      end
    end
  end
end
