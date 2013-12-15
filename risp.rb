require 'pp'
require 'parslet'
require 'parslet/convenience'

class MiniP < Parslet::Parser
  root :expression

  # Single character rules
  rule(:lparen)     { str('(') >> space? }
  rule(:rparen)     { str(')') >> space? }
  rule(:comma)      { str(',') >> space? }

  rule(:space)      { match('\s').repeat(1) }
  rule(:space?)     { space.maybe }

  # Things
  rule(:integer)    { match('[0-9]').repeat(1).as(:int) >> space? }
  rule(:identifier) { match['a-z'].repeat(1) }
  rule(:operator)   { match('[+]') >> space? }

  # Grammar parts
  rule(:sum)        { integer.as(:left) >> operator.as(:op) >> expression.as(:right) }
  rule(:arglist)    { expression >> (comma >> expression).repeat }
  rule(:funcall)    { identifier.as(:funcall) >> lparen >> arglist.as(:arglist) >> rparen }

  rule(:expression) { funcall | sum | integer }
end

class IntLit   < Struct.new(:int)
  def eval; int.to_i; end
end
class Addition < Struct.new(:left, :right)
  def eval; left.eval + right.eval; end
end
class FunCall < Struct.new(:name, :args);
  def eval
    p args.map { |s| s.eval }
  end
end

class MiniT < Parslet::Transform
  rule(:int => simple(:int))        { IntLit.new(int) }
  rule(
    :left => simple(:left),
    :right => simple(:right),
    :op => '+')                     { Addition.new(left, right) }
  rule(
    :funcall => 'puts',
    :arglist => subtree(:arglist))  { FunCall.new('puts', arglist) }
end

parser = MiniP.new
transf = MiniT.new

# ast = transf.apply(parser.parse('puts(1,2,3, 4+5)'))
# ast.eval # => [1, 2, 3, 9]

# lisp-interpreter using ruby
# ref: http://maryrosecook.com/post/little-lisp-interpreter
module RISP
  class LispParser < Parslet::Parser
    rule(:space) { match['\s'].repeat(1) }
    rule(:space?) { space.maybe }

    rule(:string) { (str('"') >> match['a-zA-Z0-9'].repeat.as(:str) >> str('"')) }
    rule(:integer) { match(['0-9']).repeat(1).as(:int) >> space? }
    rule(:symbol) { match['a-z\+\-'].repeat(1).as(:sym) }

    rule(:identifier) { string | integer | symbol }
    rule(:expression) { (str('(') >> (identifier | space | expression).repeat >> str(')')).as(:exp) }

    root :expression
  end

  str = '(+ 1 (+ 1 "daewon"))'
  LispParser.new.parse str
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
