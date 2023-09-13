# -*- coding: UTF-8 -*-

require 'json'
require 'haml'
require 'haml/magic_translations'

module Haml::MagicTranslations::RGetText # :nodoc:
  # RGetText parser for Haml files
  #
  # === Example
  #
  #   GetText::RGetText.add_parser(Haml::MagicTranslations::RGetText::HamlParser)
  #   GetText.update_pofiles(text_domain, files, app_version, options)
  #
  module HamlParser
    module_function

    def target?(file) # :nodoc:
      File.extname(file) == '.haml'
    end

    def parse(file, ary = []) # :nodoc:
      Parser.new(file).parse
    end

    class Parser # :nodoc:all
      attr_reader :file
      attr_reader :content
      def initialize(file)
        if file.respond_to? :read
          @file = '(haml)'
          @content = file.read
        else
          @file = file
          @content = File.open(file).read
        end
      end

      def parse
        Haml::Engine.send(:include, RGetTextEngine)
        engine = Haml::Engine.new(
            content, :filename => @file,
                     :rgettext => true,
                     :magic_translations => false).targets
      end
    end

    module RGetTextEngine # :nodoc:all
      def add_target(text, lineno = @node.line)
        @targets = {} if @targets.nil?
        unless text.empty?
          @targets[text] = [] unless @targets[text]
          @targets[text].push("#{options[:filename]}:#{lineno}")
        end
      end

      def targets
        (@targets || {}).keys.sort.collect do |k|
          [k] + @targets[k]
        end
      end

      # We can't piggyback `compile_tag` because the following gets no
      # distinction at all:
      #
      #     %p= "Hello"
      #
      # and:
      #
      #     %p #{"Hello"}
      #
      # So let's hook in the parser, just for this specific case.
      def parse_tag(line)
        return super unless self.options[:rgettext]

        tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
          nuke_inner_whitespace, action, value, last_line = super(line)
        if action && (action == '=' || (action == '!' && value[0] == ?=) ||
                                       (action == '&' && value[0] == ?=))
          # Search for explicitely translated strings
          value.gsub(/_\('(([^']|\\')+)'\)/) do |m|
            parsed_string = "#{$1}"
            add_target(parsed_string, last_line)
          end
        else
          interpolated = Haml::MagicTranslations.prepare_i18n_interpolation(value)
          add_target(interpolated[0], last_line)
        end
        [tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
            nuke_inner_whitespace, action, value, last_line]
      end

      def compile_plain
        return super unless self.options[:rgettext]

        add_target(@node.value[:text])
      end

      def compile_doctype
        return super unless self.options[:rgettext]
      end

      def compile_script
        return super unless self.options[:rgettext]

        yield if block_given?
      end

      def compile_silent_script
        return super unless self.options[:rgettext]

        yield if block_given?
      end

      def compile_tag
        return super unless self.options[:rgettext]

        # handle explicit translations in attributes
        @node.value[:attributes_hashes].each do |hash_string|
          hash_string.gsub(/_\('(([^']|\\')+)'\)/) do |m|
            add_target($1)
          end
        end
        # targets have been already handled in parse_tag
        yield if @node.value[:value].nil? && block_given?
      end

      def compile_filter
        return super unless self.options[:rgettext]

        case @node.value[:name]
        when 'markdown'
          add_target(@node.value[:text].rstrip.gsub(/\n/, '\n'))
        when 'javascript'
          lineno = 0
          @node.value[:text].split(/\r\n|\r|\n/).each do |line|
            lineno += 1
            line.gsub(/_\('(([^']|\\')+)'\)/) do |m|
              parsed_string = JSON.parse("[\"#{$1}\"]")[0]
              add_target(parsed_string, @node.line + lineno)
            end
          end
        end
      end
    end
  end
end
