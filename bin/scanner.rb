#!/usr/bin/env jruby
class Scanner
  def initialize(text, current_token = nil)
    @text = text
    @tokens = {}
  end

  def scan(current_token = nil)
    parsed_elements = []
    while next_character
      begin
        { :b => '*', :i => '/', :u => '_', :code => '\'', :br => '\\' }.each_pair do |token, character|
          if @current_character == character
            if next_character == character
              if current_token == token
                return parsed_elements
              else
                parsed_elements << { :token => token, :content => token == :br ? nil : scan(token) }
              end
              next_character
            else
              parsed_elements << @current_character
            end
            raise RetryScanError
          end
        end
        
        { :a => '[', :img => '{' }.each_pair do |token, character|
          if @current_character == character 
            if next_character == character
              url = url_scan(token, :url)
              text = (@current_character == '|') ? url_scan(token, :text) : url
              parsed_elements << { :token => token, :content => text, :url => format_url(url) }
              next_character
            else
              parsed_elements << character
            end
            raise RetryScanError
          end
        end
        case @current_character
        when '<'
          parsed_elements << tag_scan
        when '>'
          parsed_elements << { :token => :blockquote, :content => blockquote_scan }
        else
          parsed_elements << @current_character
        end
      rescue RetryScanError
        retry
      end
    end
    parsed_elements
  end

  def tag_scan(searched_tag = nil)
    position = @text.pos
    tags = { :email => /^\w+@[\w\.]+$/, :nowiki_end => '/nowiki', :nowiki => 'nowiki', :php_end => '/php', :php => 'php' }
    tag_name = ''
    while next_character.match(/[\w\d\.@\/]/)
      tag_name << @current_character
    end
    if @current_character == '>'
      if tag = tags.select{ |key, value| tag_name.match(value) }.first.first
        case searched_tag
        when :php
          if (tag == :php_end)
            return true
          else
            @text.pos = position
            return false
          end
        when :nowiki
          if (tag == :nowiki_end)
            return true
          else
            @text.pos = position
            return false
          end
        end

        return case tag
        when :email
          { :token => :a, :content => parsed_elements, :href=> "mailto:#{ parsed_elements }" }
        when :nowiki
          tag_inner_scan(:nowiki)
        when :php
          tag_inner_scan(:php)
        else
          { :token => :text, :content => "<#{ parsed_elements }>" }
        end
      end
    else
      @text.pos = position
      return "<"
    end
  end

  def tag_inner_scan(current_token)
    text = ''
    while next_character
      if @current_character == '<' and tag_scan(current_token) == true
        return case current_token
        when :php
          return { :token => :php, :content => text }
        when :nowiki
          return { :token => :text , :content => text } 
        end
      end
      text << @current_character
    end
    nil
  end

  def url_scan(current_token, part = :url)
    text = ''
    while next_character
      case @current_character
      when '|'
        if part == :url
          return text
        else
          text << '|'
          redo
        end
      when ']'
        if next_character == ']' and (current_token == :a)
          return text
        else
          text << ']'
          redo
        end
      when '}'
        if next_character == '}' and (current_token == :img)
          return text
        else
          text << '}'
          redo
        end
      else
        text << @current_character
      end
    end
    text
  end

  def blockquote_scan
    text = ''
    while next_character
      if @current_character.match(/\n/)
        return text
      else
        text << @current_character
      end
    end
    text
  end

  private

  def next_character
    @current_character = @text.readchar
  rescue EOFError
    nil
  end

  def format_url(url)
    if url.match(/^http:\/\/|^ftp:\/\//)
      url
    else
      '/' + url
    end
  end
end

class RetryScanError < StandardError
end
