# -*- coding: UTF-8 -*-

require 'haml'
require 'json'

##
# This plugin provides "magical translations" in your .haml files. What does it
# mean? It's mean that all your raw texts in templates will be automatically
# translated by GetText, FastGettext or Gettext backend from I18n. No more 
# complicated translation keys and ugly translation methods in views. Now you can
# only write in your language, nothing more. At the end of your work you can easy 
# find all phrases to translate and generate .po files for it. This type of files 
# are also more readable and easier to translate, thanks to it you save your 
# time with translations.
#
# === Examples
#
# Now you can write what you want, and at the end of work you 
# will easy found all phrases to translate. Check out following example:
# 
#   %p This is my simple dummy text.
#   %p And more lorem ipsum...
#   %p= link_to _("This will be also translated"), "#"
#   
# Those translations are allso allowing you to use standard Haml interpolation. 
# You can easy write: 
#   
#   %p This is my text with #{"interpolation".upcase}... Great, isn't it?
#   
# And text from codes above will be stored in .po files as:
# 
#   # File test1.haml, line 1
#   msgid "This is my simple dummy text"
#   msgstr "This is my dummy translation of dummy text"
#   
#   # File test2.haml, line 1
#   msgid "This is my text with %s... Great, isn't it?"
#   msgstr "Next one %s translation!"
#   
# Generator for .po files also includes information where your phrases are placed
# in filesystem. Thanks to it you don't forget about any even small word to 
# translate. 
# 
module Haml::MagicTranslations
  def self.included(haml) # :nodoc:
    haml.send(:include, EngineMethods)
    if defined? Haml::Template
      Haml::Template.send(:extend, TemplateMethods)
    end
  end

  # It discovers all fragments of code embeded in text and replacing with
  # simple string interpolation parameters.
  #
  # ==== Example:
  #
  # Following line...
  #
  #   %p This is some #{'Interpolated'.upcase'} text
  #
  # ... will be translated to:
  #
  #   [ "This is some %s text", "['Interpolated'.upcase]" ]
  #
  def self.prepare_i18n_interpolation(str, escape_html = nil)
    args = []
    res  = ''
    str = str.
      gsub(/\n/, '\n').
      gsub(/\r/, '\r').
      gsub(/\#/, '\#').
      gsub(/\"/, '\"').
      gsub(/\\/, '\\\\')

    rest = Haml::Shared.handle_interpolation '"' + str + '"' do |scan|
      escapes = (scan[2].size - 1) / 2
      res << scan.matched[0...-3 - escapes]
      if escapes % 2 == 1
        res << '#{'
      else
        content = eval('"' + Haml::Shared.balance(scan, ?{, ?}, 1)[0][0...-1] + '"')
        content = "Haml::Helpers.html_escape(#{content.to_s})" if escape_html
        args << content
        res  << '%s'
      end
    end
    value = res+rest.gsub(/\\(.)/, '\1').chomp
    value = value[1..-2] unless value.to_s == ''
    args  = "[#{args.join(', ')}]"
    [value, args]
  end

  def self.enabled?
    @enabled
  end

  # Enable magic translations using the given backend
  #
  # Supported backends:
  #
  # +:i18n+:: Use I18n::Backend::GetText and I18n::GetText::Helpers
  #           from the 'i18n'
  # +:gettext+:: Use GetText from 'gettext'
  # +:fast_gettext+:: Use FastGettext::Translation from 'fast_gettext'
  def self.enable(backend = :i18n)
    case backend
    when :i18n
      require 'i18n'
      require 'i18n/backend/gettext'
      require 'i18n/gettext/helpers'
      I18n::Backend::Simple.send(:include, I18n::Backend::Gettext)
      EngineMethods.magic_translations_helpers = I18n::Gettext::Helpers
    when :gettext
      require 'gettext'
      EngineMethods.magic_translations_helpers = GetText
    when :fast_gettext
      require 'fast_gettext'
      EngineMethods.magic_translations_helpers = FastGettext::Translation
    when :custom
      EngineMethods.magic_translations_helpers = nil
    else
      @enabled = false
      raise ArgumentError, "Backend #{backend.to_s} is not available in Haml::MagicTranslations"
    end
    @enabled = true
  end

  # Disable magic translations
  def self.disable
    EngineMethods.magic_translations_helpers = nil
    @enabled = false
  end

  module TemplateMethods # :nodoc:all
    # backward compatibility with versions < 0.3
    def enable_magic_translations(backend = :i18n)
      Haml::MagicTranslations.enable backend
    end
  end

  module EngineMethods # :nodoc:all
    class << self
      attr_accessor :magic_translations_helpers
    end

    def magic_translations?
      return self.options[:magic_translations] unless self.options[:magic_translations].nil?

      Haml::MagicTranslations.enabled?
    end

    # Overriden function that parses Haml tags. Injects gettext call for all plain
    # text lines.
    def parse_tag(line)
      tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value, last_line = super(line)

      if magic_translations? && !value.empty?
        unless action && action == '=' || action == '!' && value[0] == ?= || action == '&' && value[0] == ?=
          value, interpolation_arguments = Haml::MagicTranslations.prepare_i18n_interpolation(value)
          value = "\#{_('#{value.gsub(/'/, "\\\\'")}') % #{interpolation_arguments}\}\n"
        end
      end
      [tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
         nuke_inner_whitespace, action, value, last_line]
    end

    # Magical translations will be also used for plain text.
    def plain(text, escape_html = nil)
      if magic_translations?
        value, interpolation_arguments = Haml::MagicTranslations.prepare_i18n_interpolation(text, escape_html)
        value = "_('#{value.gsub(/'/, "\\\\'")}') % #{interpolation_arguments}\n"
        script(value, !:escape_html)
      else
        super
      end
    end

    def compile_filter
      super unless magic_translations?

      case @node.value[:name]
        when 'markdown'
          @node.value[:text] = "\#{_(<<-'END_OF_TRANSLATABLE_MARKDOWN'.rstrip
#{@node.value[:text].rstrip.gsub(/\n/, '\n')}
END_OF_TRANSLATABLE_MARKDOWN
)}"
        when 'javascript'
          @node.value[:text].gsub!(/_\(('(([^']|\\')+)'|"(([^"]|\\")+)")\)/) do |m|
            to_parse = $1[1..-2].gsub(/"/, '\"')
            parsed_string = JSON.parse("[\"#{to_parse}\"]")[0]
            parsed_string.gsub!(/'/, "\\\\'")
            "\#{_('#{parsed_string}').to_json}"
          end
      end
      super
    end

    def compile_root
      if magic_translations? && EngineMethods.magic_translations_helpers
        @precompiled << "extend #{EngineMethods.magic_translations_helpers};"
      end
      super
    end
  end
end

Haml::Engine.send(:include, Haml::MagicTranslations)
