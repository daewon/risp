# lisp-interpreter using ruby
# ref: http://maryrosecook.com/post/little-lisp-interpreter
require 'ostruct'

module RISP
  class Interpreter
    class Context
      def initialize scope, parent
        @scope, @parent = scope, parent
      end

      def get identifier
        if @scope[identifier]
          @scope[identifier]
        elsif @parent
          return @parent.get identifier
        end
      end
    end

    def initialize
      @library = {
        'first' => -> x { x[0] },
        'rest' => -> x { x[1..-1] },
        'print' => -> x {
          puts x.inspect
          x
        },
        '+' => -> *args { args.reduce(0) { |acc, n| acc + n } },
        'list' => -> *args { args },
      }

      # spectial forms
      @special = {
        'lambda' => -> input, context {
          -> *lambdaArguments {
            scope = input[1].each_with_index.reduce({}) { |acc, (x, i)|
              acc.merge( { x[:value] => lambdaArguments[i] } )
            }

            (interpret input[2..-1], Context.new(scope, context)).last
          }
        },
        'define' => -> input { }
      }
    end

    def interpret input, context = nil
      if context.nil?
        interpret input, Context.new(@library, nil)
      elsif input.kind_of? Array
        interpretList input, context
      elsif input[:type] == :identifier
        context.get input[:value]
      else
        input[:value]
      end
    end

    def interpretList input, context
      if !(input[0].kind_of? Array) and @special[input[0][:value]]
        @special[input[0][:value]].call input, context
      else
        list = input.map { |x| interpret x, context }
        if list[0].kind_of? Proc
          list[0].call *list[1..-1]
        else
          list
        end
      end
    end

  end

  class Parser
    def parse input
      parenthesize tokenize(input)
    end

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
