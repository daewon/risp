module RISP
  class Parser
    def tokenize input
      input.gsub(/([\(\)])/, ' \1 ').strip.split(/\s+/);
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
