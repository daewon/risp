# lisp-interpreter using ruby
# ref: http://maryrosecook.com/post/little-lisp-interpreter
module RISP
  class Interpreter
    class Context
      def initialize scope = {}, parent = nil
        @scope, @parent = scope, parent
      end

      def set identifier, value
        @scope[identifier] = value
      end

      def get identifier
        if @scope[identifier]
          @scope[identifier]
        else
          @parent and @parent.get identifier
        end
      end
    end

    def initialize
      @library = {
        'print' => -> x { puts x; x },
        'list' => -> *args { args },
        'hd' => -> x { x[0] },
        'tail' => -> x { x[1..-1] },
        '+' => -> *args { args.reduce(0) { |acc, n| acc + n } },
        '-' => -> *args { args[1..-1].reduce(args[0]) { |acc, n| acc - n } },
        '*' => -> *args { args.reduce(1) { |acc, n| acc * n } },
        '/' => -> *args { args[1..-1].reduce(args[0]) { |acc, n| acc / n } }
      }

      # spectial forms
      @special = {
        'lambda' => -> input, context {
          -> *lambdaArguments {
            scope = input[1].each_with_index.reduce({}) { |acc, (x, i)|
              acc.merge( { x[:value] => lambdaArguments[i] } )
            }
            interpret input[2], Context.new(scope, context)
          }
        },
        'let' => -> input, context {
          scope = input[1].each_slice(2).reduce({}) { |acc, (a, b)|
            if b.kind_of? Array
              acc.merge({a[:value] => (interpret b, context)})
            else
              acc.merge({a[:value] => b[:value]})
            end
          }
          interpret input[2], Context.new(scope, context)
        },
        'if' => -> input, context {
          if interpret input[1]
            interpret input[2], context
          else
            interpret input[3], context
          end
        },
        'progn' => -> input, context {
          input[1..-1].map { |e| interpret e, context }.last
        },
        'define' => -> input, context {
          context.set input[1][:value], (interpret input[2])
        }
      }
    end

    def interpret input, context = nil
      if context.nil?
        interpret input, (Context.new @library)
      elsif input.kind_of? Array
        interpretList input, context
      elsif input[:type] == :identifier
        context.get input[:value]
      else
        input[:value]
      end
    end

    def interpretList input, context
      head = input.first
      if !(head.kind_of? Array) and @special[head[:value]]
        @special[head[:value]].call input, context
      else
        list = input.map { |x| interpret x, context }
        list.first.call( *list[1..-1] )
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
      elsif input[0] == '"' and input[-1] == '"'then
        {type: :literal, value: input[1...-1]}
      elsif input == '#t' then
        {type: :literal, value: true}
      elsif input == '#f' then
        {type: :literal, value: false}
      else
        {type: :identifier, value: input}
      end
    end

    def parenthesize list
      tokens = list.dup # mutable list

      _parenthesize = -> acc {
        return acc.pop if tokens.empty?
        token = tokens.shift

        case token
        when '(' then acc << (_parenthesize.call [])
        when ')' then return acc # explicit return
        else acc << categorize(token)
        end
        _parenthesize.call acc
      }

      _parenthesize.call []
    end
  end
end
