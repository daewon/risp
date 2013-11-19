require './risp'

describe RISP do
  let(:parser) { RISP::Parser.new }
  let(:interpreter) { RISP::Interpreter.new }
  before :each do;end

  it "token" do
    expect = %w{ ( ( lambda ( x ) x ) "Lisp" ) }
    parser.tokenize('((lambda (x) x) "Lisp")').should eql expect
  end

  it "parenthesize" do
    tokens = %w{ ( ( lambda ( x ) x ) "Lisp" ) }
    expect = [[{ type: :identifier, value: 'lambda' },[{ type: :identifier, value: 'x' }], { type: :identifier, value: 'x' }],
              { type: :literal, value: 'Lisp' }]
    parser.parenthesize(tokens).should eql expect
  end

  it "interpret" do
    parens = parser.parse '"daewon"'
    interpreter.interpret(parens).should eql "daewon"

    parens = parser.parse '#t'
    interpreter.interpret(parens).should eql true

    parens = parser.parse '#f'
    interpreter.interpret(parens).should eql false

    parens = parser.parse '1'
    interpreter.interpret(parens).should eql 1

    parens = parser.parse '(+ 1 2)'
    interpreter.interpret(parens).should eql 3

    parens = parser.parse '(list 1 2)'
    interpreter.interpret(parens).should eql [1, 2]

    parens = parser.parse '(lambda (x) x)'
    interpreter.interpret(parens).should be_a_kind_of Proc

    parens = parser.parse '((lambda (x) x) 100)'
    interpreter.interpret(parens).should eql 100

    parens = parser.parse '(list (lambda (x) x) 100)'
    interpreter.interpret(parens).length.should eql 2
    interpreter.interpret(parens).first.should be_a_kind_of Proc
    interpreter.interpret(parens).last.should eql 100

    parens = parser.parse '((lambda (a) ((lambda (b) a) a)) 100)'
    interpreter.interpret(parens).should eql 100

    parens = parser.parse '(((lambda (a) (lambda (b) a)) 100))'
    interpreter.interpret(parens).should eql 100

    parens = parser.parse '(let (x 10) (* x x))'
    interpreter.interpret(parens).should eql 100

    parens = parser.parse '(let (x 10 y 100) (* x y))'
    interpreter.interpret(parens).should eql 1000

    parens = parser.parse '(if #t 10 20)'
    interpreter.interpret(parens).should eql 10

    parens = parser.parse '(if #f 10 20)'
    interpreter.interpret(parens).should eql 20

    parens = parser.parse '(if #f (print 100) 20)'
    interpreter.interpret(parens).should eql 20

    parens = parser.parse '(let (f (lambda (a) a) x 100) (f x))'
    interpreter.interpret(parens).should eql 100
  end
end
