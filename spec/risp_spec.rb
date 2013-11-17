require './risp'

describe RISP do
  let(:parser) { RISP::Parser.new }
  before :each do;end

  it "token" do
    parser.send(:tokenize, '((lambda (x) x) "Lisp")').should eql %w{ ( ( lambda ( x ) x ) "Lisp" ) }
  end

  it "parenthesize" do
    tokens = %w{ ( ( lambda ( x ) x ) "Lisp" ) }
    expect = [[{ type: :identifier, value: 'lambda' },[{ type: :identifier, value: 'x' }], { type: :identifier, value: 'x' }], { type: :literal, value: 'Lisp' }]
    parser.send(:parenthesize, tokens).should eql expect
  end

  it "interpret" do
    str = '((lambda (x) x) "Lisp")'
    tokens = parser.send :tokenize, str
    parens = parser.send :parenthesize, tokens
    RISP::interpret(parens, nil).should eql "Lisp"

    str = '((first (list (lambda (x) x) "Lisp")) "daewon")'
    tokens = parser.send :tokenize, str
    parens = parser.send :parenthesize, tokens
    RISP::interpret(parens, nil).should eql "daewon"

    str = '(+ 1 2 3 4 5)'
    tokens = parser.send :tokenize, str
    parens = parser.send :parenthesize, tokens
    RISP::interpret(parens, nil).should eql 15

  end
end
