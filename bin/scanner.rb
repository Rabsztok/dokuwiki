#!/usr/bin/env ruby

class Scanner
  
  def initialize(text, opened = nil)
    @text = text
    @tokens = {}
  end
  
  def run
    return scan
  end
    
  def scan(opened = nil)
    text_buffer = ''
    while get_char
      begin
        case @char
        when '*'
          case get_char
          when '*'
            if opened == :b
              return text_buffer
            else
              text_buffer += "<b>#{ scan(:b) }</b>"
            end
          else
            text_buffer += '*'
            raise RetryError
          end
        when '/'
          case get_char
          when '/'
            if opened == :i
              return text_buffer
            else
              text_buffer += "<i>#{ scan(:i) }</i>"
            end
          else
            text_buffer += '/'
            raise RetryError
          end
        when '_'
          case get_char
          when '_'
            if opened == :u
              return text_buffer
            else
              text_buffer += "<u>#{ scan(:u) }</u>"
            end
          else
            text_buffer += '_'
            raise RetryError
          end
        when '\''
          case get_char
          when '\''
            if opened == :code
              return text_buffer
            else
              text_buffer += "<code>#{ scan(:code) }</code>"
            end
          else
            text_buffer += '\''
            raise RetryError
          end
        when '\\'
          case get_char
          when '\\'
            if opened == :br
              return text_buffer
            else
              text_buffer += "<br/>"
            end
          else
            text_buffer += '\\'
            raise RetryError
          end
        when '['
          case get_char
          when '['
            href = url_scan(:link_href)
            text = (@char == '|') ? url_scan(:link_text) : href
            text_buffer += "<a href='#{ format_url(href) }'>#{ text }</a>"
          else
            text_buffer += '['
            raise RetryError
          end
        when '{'
          case get_char
          when '{'
            href = url_scan(:img_href)
            text = (@char == '|') ? url_scan(:img_text) : href
            text_buffer += "<img src='#{ format_url(href) }' title='#{ text }' />"
          else
            text_buffer += '{'
            raise RetryError
          end
        when '|'
          case opened
          when :link_href
            return text_buffer
          else
            text_buffer += '|'
          end
        when ']'
          if get_char == ']' and (opened == :link_href or opened == :link_text)
            return text_buffer
          else
            text_buffer += ']'
            raise RetryError
          end
        when '<'
          text_buffer += tag_scan
        when '>'
          text_buffer += "<blockquote>#{ blockquote_scan }</blockquote>"
        else
          text_buffer += @char.to_s
        end
      rescue RetryError
        retry
      end
    end
    return text_buffer
  end
  
  def tag_scan(searched_tag = nil)
    position = @text.pos
    text_buffer = ''
    tags = [/^\w+@[\w\.]+$/, '/nowiki', 'nowiki', '/php', 'php']
    while get_char.match(/[\w\d\.@\/]/)
      text_buffer << @char
    end
    if @char == '>'
      if index = tags.find_index{ |element| text_buffer.match(element) }
        case searched_tag
        when :php
          if (index == 3)
            return true
          else
            @text.pos = position
            return false
          end
        when :nowiki
          if (index == 1)
            return true
          else
            @text.pos = position
            return false
          end
        end
        
        return case index
        when 0
           "<a href='mailto:#{ text_buffer }'>#{ text_buffer }</a>"
        when 2
          tag_inner_scan(:nowiki)
        when 4
          "<?php #{ tag_inner_scan(:php) }"
        else
          "<#{ text_buffer }>" 
        end
      end
    else
      @text.pos = position
      return "<"
    end
  end
  
  def tag_inner_scan(opened)
    text_buffer = ''
    while get_char
      begin
        if @char == '<'
          if tag_scan(opened) == true
            return case opened
            when :php
              "#{ text_buffer } ?>"
            when :nowiki
              text_buffer
            end
          else
            text_buffer << tag_scan(opened)
          end
        else
          text_buffer << @char
        end
      rescue RetryError
        retry
      end
    end
    return text_buffer
  end
  
  def url_scan(opened = nil)
    text_buffer = ''
    while get_char
      begin
        case @char
        when '|'
          if opened == :link_href or opened == :img_href
            return text_buffer
          
          else
            text_buffer += '|'
          end
        when ']'
          if get_char == ']' and (opened == :link_href or opened == :link_text)
            return text_buffer
          else
            text_buffer += ']'
            raise RetryError
          end
        when '}'
          if get_char == '}' and (opened == :img_href or opened == :img_text)
            return text_buffer
          else
            text_buffer += '}'
            raise RetryError
          end
        else
          text_buffer += @char
        end
      rescue RetryError
        retry
      end
    end
    return text_buffer
  end
  
  def blockquote_scan
    text_buffer = ''
    while get_char
      if @char.match(/\n/)
        return text_buffer
      else
        text_buffer += @char
      end
    end
    return text_buffer
  end
  
  private
  
  def get_char
    @char = @text.readchar
  rescue EOFError
    return nil
  end
  
  def format_url(url)
    if url.match(/^http:\/\/|^ftp:\/\//)
      url
    else
      '/' + url
    end
  end
  
end

class RetryError < StandardError
end
