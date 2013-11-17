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
    parens = parser.parse '((lambda (x) x) "Lisp")'
    interpreter.interpret(parens).should eql "Lisp"

    parens = parser.parse '((first (list (lambda (x) x) "Lisp")) "daewon")'
    interpreter.interpret(parens).should eql "daewon"

    str = '(+ 1 2 3 4 5)'
    parens = parser.parse str
    interpreter.interpret(parens).should eql 15

    parens = parser.parse '"daewon"'
    interpreter.interpret(parens).should eql "daewon"

    parens = parser.parse '((lambda (x) (print 10) (+ x 2) ) 10)'
    interpreter.interpret(parens).should eql 12
  end
end
