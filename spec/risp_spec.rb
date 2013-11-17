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


  end
end

# it('should return correct result for lambda that takes and returns arg', function() {
#       expect(t.interpret(t.parse("((lambda (x) x) 1)"))).toEqual(1);
#   });

# it('should return correct result for lambda that returns list of vars', function() {
#       expect(t.interpret(t.parse("((lambda (x y) (x y)) 1 2)"))).toEqual([1, 2]);
#   });

# it('should get correct result for lambda that returns list of lits + vars', function() {
#       expect(t.interpret(t.parse("((lambda (x y) (0 x y)) 1 2)"))).toEqual([0, 1, 2]);
#   });

# it('should return correct result when invoke lambda w params', function() {
#       expect(t.interpret(t.parse("((lambda (x) (first (x))) 1)")))
#       .toEqual(1);
#   });
#                    });
