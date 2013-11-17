# [1;[1;3B3Blittle]]-lisp-interpreter using ruby
# http://maryrosecook.com/post/little-lisp-interpreter
require 'ostruct'

module RISP
  @@library = {
    'first' => -> x { x[0] },
    'rest' => -> x { x[1..-1] },
    'print' => -> x {
      puts x.inspect
      x
    },
    '+' => -> a, b { a + b },
    '*' => -> a, b { a * b },
    'list' => -> *args { args },
  }

  class Context
    def initialize scope, parent
      @scope = scope
      @parent = parent
    end

    def get identifier
      if @scope[identifier]
        @scope[identifier]
      elsif @parent
        return @parent.get identifier
      end
    end
  end

  @@special = {
    'lambda' => -> input, context {
      -> *lambdaArguments {
        scope = input[1].each_with_index.reduce({}) { |acc, (x, i)|
          acc[x[:value]] = lambdaArguments[i]
          acc
        }
        interpret input[2], Context.new(scope, context)
      }
    }
  }

  def self.interpret input, context
    if context.nil?
      interpret input, Context.new(@@library, nil)
    elsif input.kind_of? Array
      interpretList input, context
    elsif input[:type] == :identifier
      context.get input[:value]
    else
      input[:value]
    end
  end

  def self.interpretList input, context
    if !(input[0].kind_of? Array) and @@special[input[0][:value]]
      @@special[input[0][:value]].call input, context
    else
      list = input.map { |x| interpret x, context }
      if list[0].kind_of? Proc
        list[0].call *list[1..-1]
      else
        list
      end
    end
  end

  class Parser
    def parse input
      parenthesize tokenize(input)
    end

    private
    def tokenize input
      input.gsub(/([\(\)])/, ' \1 ').strip.split(/\s+/)
    end

    def categorize input
      is_digit = -> value { value.to_i.to_s == value }

      if is_digit.call input
        {type: :literal, value: input.to_i}
      elsif input[0] == '"' then
        {type: :literal, value: input[1...-1]}
      else
        {type: :identifier, value: input}
      end
    end

    def parenthesize list
      tokens = list.dup # mutable list
      paren = -> acc {
        return acc.pop if tokens.empty?
        token = tokens.shift

        case token
        when '(' then acc << (paren.call [])
        when ')' then return acc # explicit return
        else acc << categorize(token) end

        paren.call acc
      }
      paren.call []
    end
  end
end
