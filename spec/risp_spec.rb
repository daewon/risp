require './risp'

describe RISP do
  let(:parser) { RISP::Parser.new }
  before :each do;end

  it "token" do
    parser.tokenize('((lambda (x) x) "Lisp")').should eql %w{ ( ( lambda ( x ) x ) "Lisp" ) }
  end

  it "parenthesize" do
    tokens = %w{ ( ( lambda ( x ) x ) "Lisp" ) }
    expect = [[{ type: :identifier, value: 'lambda' },[{ type: :identifier, value: 'x' }], { type: :identifier, value: 'x' }],
              { type: :literal, value: 'Lisp' }]
    parser.parenthesize(tokens).should eql expect

  end
end
