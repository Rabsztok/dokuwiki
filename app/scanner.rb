#!/usr/bin/env ruby

class Scanner
  def initialize(text, opened = nil)
    @text = text
    @text_buffer = ''
    @opened = opened
    @tokens = {}
  end
  
  def run
    while get_char
      begin
        case @char
        when '*'
          case get_char
          when '*'
            if @opened == :b
              return @text_buffer
            else
              @text_buffer += "<b>#{ Scanner.new(@text, :b).run }</b>"
            end
          else
            @text_buffer += '*'
            raise RetryError
          end
        when '/'
          case get_char
          when '/'
            if @opened == :i
              return @text_buffer
            else
              @text_buffer += "<i>#{ Scanner.new(@text, :i).run }</i>"
            end
          else
            @text_buffer += '/'
            raise RetryError
          end
        when '_'
          case get_char
          when '_'
            if @opened == :u
              return @text_buffer
            else
              @text_buffer += "<u>#{ Scanner.new(@text, :u).run }</u>"
            end
          else
            @text_buffer += '_'
            raise RetryError
          end
        else
          @text_buffer += @char
        end
      rescue RetryError
        retry
      end
    end
    return @text_buffer
  end
  
  def get_char
    @char = @text.readchar
  rescue EOFError
    return nil
  end
end

class RetryError < StandardError
end
