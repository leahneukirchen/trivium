require 'strscan'

class HTemplate
  def initialize(source, filename=nil)
    @source = source
    @filename = filename
    compile
  end

  if defined? Rack::Utils
    def escape_html(s)
      Rack::Utils.escape_html s
    end
  else
    require 'cgi'
    def escape_html(s)
      CGI.escapeHTML s
    end
  end

  def expand(data, output="", escape=nil, &block)
    escape ||= lambda { |v|
      escape_html v.to_s
    }
    @code.call(output, data, block, escape)
    output
  end

  def compile
    code = "lambda { |output, data, block, __escape| data.instance_eval {\n"

    scanner = StringScanner.new(@source)

    until scanner.eos?
      if scanner.bol? and scanner.scan(/\s*\$ (.*\n)/)
                                           # raw line of code, $ if bla
        code << scanner[1]
      elsif scanner.scan(/\$(:?)(\{(.*?)\}|(@?[\w.!?]+))/)
                                           # expression, ${foo} or $foo.bar
        expr = scanner[3] || scanner[4]

        if scanner[1] == ":"               # disable escaping?
          code << %Q{output << (#{expr}).to_s;}
        else
          code << %Q{output << __escape[#{expr}];}
        end
      elsif scanner.scan(/\$\$/)           # plain $
        code << %Q{output << '$';}
      elsif scanner.scan(/\$#.*?(?:#\$|$\n?)/)  # comment $#...#$ or $#...
        # nothing
      elsif scanner.scan(/([^\n$]+\n?)|([^\n$]*\n)/)   # text
        if scanner.matched =~ /\\$/ && scanner.bol?
          code << %Q{output << #{scanner.matched.chop.chop.dump};}
        else
          code << %Q{output << #{scanner.matched.dump};}
        end

        code << "\n"  if scanner.bol?
      else
        raise "can't parse template: #{scanner.rest[0..20].dump}"
      end
    end

    code << "}}"

    @code = eval(code, nil, @filename || '(template)', 0)
  end
end
