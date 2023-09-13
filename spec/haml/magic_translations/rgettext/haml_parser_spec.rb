# -*- coding: UTF-8 -*-

require 'spec_helper'
require 'haml/magic_translations/rgettext/haml_parser'

module Haml::MagicTranslations::RGetText
  describe HamlParser do
    describe '.target?' do
      subject { HamlParser }

      context 'when given example.rb' do
        it { should_not be_a_target('example.rb') }
      end
      context 'when given example.haml' do
        it { should be_a_target('example.haml') }
      end
    end

    describe '.parse' do
      it 'should properly instanciate a Parser' do
        HamlParser::Parser.should_receive(:new).with('test.haml').
            and_return(mock('Parser').as_null_object)
        HamlParser.parse('test.haml')
      end
      it 'should run the parser' do
        parser = mock('Parser')
        parser.should_receive(:parse)
        HamlParser::Parser.stub!(:new).and_return(parser)
        HamlParser.parse('test.haml')
      end
    end

    describe HamlParser::Parser do
      describe '#initialize' do
        context 'when given "test.haml"' do
          before(:each) do
            File.stub!(:open).and_return(StringIO.new('It works!'))
            @parser = HamlParser::Parser.new('test.haml')
          end
          it 'should set file attribute' do
            @parser.file.should == 'test.haml'
          end
          it 'should put the file content in the content attribute' do
            @parser.content.should == 'It works!'
          end
        end
        context 'when given a IO-like object' do
          let (:parser) { HamlParser::Parser.new(StringIO.new('It works!')) }
          it { parser.file.should == '(haml)' }
          it { parser.content.should == 'It works!' }
        end
      end

      describe '#parse' do
        subject { HamlParser::Parser.new(StringIO.new(template)).parse }
        context 'for an empty content' do
          let(:template) { '' }
          it 'should return no targets' do
            should == []
          end
        end
        context 'for a translatable plain string' do
          let(:template) { 'It works!' }
          it 'should return a target' do
            should == [['It works!', '(haml):1']]
          end
        end
        context 'for two translatable plain strings' do
          let(:template) do <<-HAML.strip_heredoc
              First line
              Second line
            HAML
          end
          it 'should return two targets (with proper lines)' do
            should == [['First line', '(haml):1'],
                       ['Second line', '(haml):2']]
          end
        end
        context 'for a translatable tag' do
          let(:template) { '%p Hello!' }
          it 'should add its content' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for a translatable escaped tag' do
          let(:template) { '%p! Hello!' }
          it 'should add its content' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for a translatable unescaped tag' do
          let(:template) { '%p& Hello!' }
          it 'should add its content' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for an evaluated tag' do
          let(:template) { '%p= "Hello!"' }
          it 'should not add its content' do
            should == []
          end
        end
        context 'for an evaluated escaped tag' do
          let(:template) { '%p!= Hello!' }
          it 'should not add its content' do
            should == []
          end
        end
        context 'for an evaluated unescaped tag' do
          let(:template) { '%p&= Hello!' }
          it 'should not add its content' do
            should == []
          end
        end
        context 'for an evaluated tag with an explicitely translatable string' do
          let(:template) { "%p= _('Hello!')" }
          it 'should add the content of the string' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for an evaluated escaped tag with an explicitely translatable string' do
          let(:template) { "%p!= _('Hello!')" }
          it 'should add the content of the string' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for an evaluated unescaped tag with an explicitely translatable string' do
          let(:template) { "%p&= _('Hello!')" }
          it 'should add the content of the string' do
            should == [['Hello!', '(haml):1']]
          end
        end
        context 'for an explicit translation in an attribute' do
          let(:template) { "%input(type=submit){ value => _('Upload') }" }
          it 'should appear as a target' do
            should == [['Upload', '(haml):1']]
          end
        end
        context 'for a translatable string appearing twice' do
          let(:template) do <<-HAML.strip_heredoc
            %p Hello!
            %span= _('Hello!')
            HAML
          end
          it 'should appear only once in the targets' do
            subject.collect { |t| t[0] }.should have(1).item
          end
          it 'should record two target locations' do
            should == [['Hello!', '(haml):1', '(haml):2']]
          end
        end
        context 'for one interpolated string' do
          let(:template) { '%p Hello #{name}!' }
          it 'should replace with %s' do
            should == [['Hello %s!', '(haml):1']]
          end
        end
        context 'for two interpolated strings' do
          let(:template) { '%p Hello #{name}! Welcome to #{place}.' }
          it 'should replace them with %s' do
            should == [['Hello %s! Welcome to %s.', '(haml):1']]
          end
        end
        context 'for translatable strings in Javascript' do
          let(:template) do <<-HAML.strip_heredoc
            :javascript
              var lines = [ _('First line'),
                            _('Second line') ]
            HAML
          end
          it 'should properly identify them' do
            should == [['First line', '(haml):2'],
                       ['Second line', '(haml):3']]
          end
        end
        context 'for Javascript strings with quotes' do
          let(:template) do <<-HAML.strip_heredoc
            :javascript
              var text = _('L\\'article');
            HAML
          end
          it 'should properly identify them' do
            should == [["L'article", '(haml):2']]
          end
        end
        context 'for markdown block' do
          let(:template) do <<-HAML.strip_heredoc
            :markdown
              First paragraph

              Second paragraph
            HAML
          end
          it 'should properly add it to translations' do
             should == [["First paragraph\\n\\nSecond paragraph", '(haml):1']]
          end
        end
        context 'after extracting translations' do
          it 'should still allow Haml::Engine to build templates' do
            HamlParser::Parser.new(StringIO.new('test')).parse
            Haml::Engine.new('%p It works!').render.should == <<-'HTML'.strip_heredoc
              <p>It works!</p>
            HTML
          end
        end
      end
    end
  end
end
