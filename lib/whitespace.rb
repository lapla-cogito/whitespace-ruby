require "strscan"

class Whitespace
  def initialize
    if ARGV.length != 1
      raise Exception, "invalid arguments"
    end
    @code = ""
    @file = open(ARGV[0])
    @file.each do |line|
      @code << line
    end
    sanitize
    @tokens = tokenize
    evaluate
  end

  def sanitize
    @code.gsub!(/[^ \t\n]/, "")
  end

  def tokenize
    result = []
    scanner = StringScanner.new(@code)
    while !(scanner.eos?)
      param = nil
      unless scanner.scan(/\A( |\n|\t[ \n\t])/)
        raise Exception, "undefined imp"
      end
      imps = {
        " " => :stack,
        "\t " => :arithmetic,
        "\t\t" => :heap,
        "\n" => :flow,
        "\t\n" => :io,
      }
      imp = imps[scanner[0]]
      case imp
      when :stack
        unless scanner.scan(/ |\n[ \t\n]/)
          raise Exception, "undefined cmd of stack"
        end
        cmds = {
          " " => :push,
          "\n " => :duplicate,
          "\n\t" => :swap,
          "\n\n" => :discard,
          "\t " => :copy,
          "\t\n" => :slide,
        }
        cmd = cmds[scanner[0]]
        if cmd == :push || cmd == :copy || cmd == :slide
          unless scanner.scan(/[ \t]+\n/)
            raise Exception, "undefined parammeter of stack"
          end
          param = scanner[0]
        end
      when :arithmetic
        unless scanner.scan(/ [ \t\n]|\t[ \t]/)
          raise Exception, "undefined cmd of arithmetic"
        end
        cmds = {
          "  " => :add,
          " \t" => :sub,
          " \n" => :mul,
          "\t " => :div,
          "\t\t" => :mod,
        }
        cmd = cmds[scanner[0]]
      when :heap
        unless scanner.scan(/ |\t/)
          raise Exception, "undefined cmd of heap"
        end
        cmds = {
          " " => :store,
          "\t" => :retrieve,
        }
        cmd = cmds[scanner[0]]
      when :flow
        unless scanner.scan(/ [ \t\n]|\t[ \t\n]|\n\n/)
          raise Exception, "undefined cmd of flow"
        end
        cmds = {
          "  " => :mark,
          " \t" => :call,
          " \n" => :jmp,
          "\t " => :jz,
          "\t\t" => :jmi,
          "\t\n" => :ret,
          "\n\n" => :exit,
        }
        cmd = cmds[scanner[0]]
        unless (cmd == :ret) || (cmd == :exit)
          unless scanner.scan(/[ \t]+\n/)
            raise Exception, "undefined parammeter of flow"
          end
          param = scanner[0]
        end
      when :io
        unless scanner.scan(/ [ \t]|\t[ \t]/)
          raise Exception, "undefined cmd of io"
        end
        cmds = {
          "  " => :o_char,
          " \t" => :o_num,
          "\t " => :i_char,
          "\t\t" => :i_num,
        }
        cmd = cmds[scanner[0]]
      end
      if param != nil
        param.gsub!(/ /, "0").gsub!(/\t/, "1")
        sign = param.slice!(0)
        param = param.to_i(2)
        if sign == "1"
          param = param * -1
        end
      end
      result << [imp, cmd, param]
    end
    result
  end

  def evaluate
    @stack = []
    @call_stack = []
    @heap = {}
    pc = 0
    count = 0
    while pc < @tokens.length
      imp, cmd, param = @tokens[pc]
      count += 1
      case imp
      when :stack
        pc += 1
        case cmd
        when :push
          @stack.push(param)
        when :duplicate
          @stack.push(@stack.last)
        when :swap
          @stack[-1], @stack[-2] = @stack[-2], @stack[-1]
        when :discard
          @stack.pop
        when :copy
          @stack.push(@stack[-param.to_i(2) - 1])
        when :slide
          elm = @stack.pop
          param.to_i(2).times do
            @stack.pop
          end
          @stack.push(elm)
        end
      when :arithmetic
        pc += 1
        elm, elm2 = @stack.pop, @stack.pop
        case cmd
        when :add
          @stack.push(elm2 + elm)
        when :sub
          @stack.push(elm2 - elm)
        when :mul
          @stack.push(elm2 * elm)
        when :div
          @stack.push(elm2 / elm)
        when :mod
          @stack.push(elm2 % elm)
        end
      when :heap
        pc += 1
        case cmd
        when :store
          value, key = @stack.pop, @stack.pop
          @heap[key] = value
        when :retrieve
          key = @stack.pop
          if @heap[key] == nil
            raise Exception, "not found key for heap"
          end
          @stack.push(@heap[key])
        end
      when :flow
        case cmd
        when :mark
          pc += 1
        when :jmp
          n = 0
          @tokens.each { |im, cm, pa|
            if cm == :mark && pa == param
              pc = n + 1
            end
            n += 1
          }
        when :call
          @call_stack.push(pc)
          n = 0
          @tokens.each { |im, cm, pa|
            if cm == :mark && pa == param
              pc = n + 1
            end
            n += 1
          }
        when :jz
          if @stack.pop == 0
            n = 0
            @tokens.each { |im, cm, pa|
              if cm == :mark && pa == param
                pc = n + 1
              end
              n += 1
            }
          else
            pc += 1
          end
        when :jmi
          if @stack.pop < 0
            n = 0
            @tokens.each { |im, cm, pa|
              if cm == :mark && pa == param
                pc = n + 1
              end
              n += 1
            }
          else
            pc += 1
          end
        when :ret
          pc = @call_stack.pop
          pc += 1
        when :exit
          exit
        end
      when :io
        pc += 1
        case cmd
        when :o_char
          print @stack.pop.chr
        when :o_num
          puts @stack.pop.to_s
        when :i_char
          print "input: "
          value = STDIN.gets.ord
          @heap[param] = value
        when :i_num
          print "input: "
          value = STDIN.gets.to_i
          @heap[param] = value
        end
      end
    end
  end
end

Whitespace.new
