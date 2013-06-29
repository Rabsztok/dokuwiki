#!/usr/bin/env jruby
class Parser
  def parse(tokens)
    text = ''
    tokens.each do |element|
      if element.is_a? Hash
        case element[:token]
        when :b, :i, :u, :code, :blockquote
          text << "<#{ element[:token].to_s }>#{ get_content(element) }</#{ element[:token]} >"
        when :br
          text << '<br/>'
        when :a
          text << "<a href='#{ element[:url] }'>#{ get_content(element) }</a>"
        when :img
          text << "<img src='#{ element[:url] }' title='#{ get_content(element) }' />"
        when :php
          text << "<?php #{ get_content(element) } ?>"
        when :text
          text << get_content(element)
        end
      else
        text << element.to_s
      end
    end
    text
  end
  
  def get_content(element)
    if element[:content].is_a? Array
      parse(element[:content])
    else
      element[:content]
    end
  end
end