require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestTokenizer < Nokogiri::TestCase
      def setup
        @scanner = Nokogiri::CSS::Tokenizer.new
      end

      def test_not_equal
        @scanner.scan("h1[a!='Tender Lovemaking']")
        assert_tokens([ [:IDENT, 'h1'],
                        ['[', '['],
                        [:IDENT, 'a'],
                        [:NOT_EQUAL, '!='],
                        [:STRING, "'Tender Lovemaking'"],
                        [']', ']'],
        ], @scanner)
      end

      def test_function
        @scanner.scan("script comment()")
        assert_tokens([ [:IDENT, 'script'],
                        [:S, ' '],
                        [:FUNCTION, 'comment('],
                        [')', ')'],
        ], @scanner)
      end

      def test_preceding_selector
        @scanner.scan("E ~ F")
        assert_tokens([ [:IDENT, 'E'],
                        [:TILDE, ' ~'],
                        [:S, ' '],
                        [:IDENT, 'F'],
        ], @scanner)
      end

      def test_scan_attribute_string
        @scanner.scan("h1[a='Tender Lovemaking']")
        assert_tokens([ [:IDENT, 'h1'],
                        ['[', '['],
                        [:IDENT, 'a'],
                        ['=', '='],
                        [:STRING, "'Tender Lovemaking'"],
                        [']', ']'],
        ], @scanner)
        @scanner.scan('h1[a="Tender Lovemaking"]')
        assert_tokens([ [:IDENT, 'h1'],
                        ['[', '['],
                        [:IDENT, 'a'],
                        ['=', '='],
                        [:STRING, '"Tender Lovemaking"'],
                        [']', ']'],
        ], @scanner)
      end

      def test_scan_id
        @scanner.scan('#foo')
        assert_tokens([ [:HASH, '#foo'] ], @scanner)
      end

      def test_scan_pseudo
        @scanner.scan('a:visited')
        assert_tokens([ [:IDENT, 'a'],
                        [':', ':'],
                        [:IDENT, 'visited']
        ], @scanner)
      end

      def test_scan_star
        @scanner.scan('*')
        assert_tokens([ ['*', '*'], ], @scanner)
      end

      def test_scan_class
        @scanner.scan('x.awesome')
        assert_tokens([ [:IDENT, 'x'],
                        ['.', '.'],
                        [:IDENT, 'awesome'],
        ], @scanner)
      end

      def test_scan_greater
        @scanner.scan('x > y')
        assert_tokens([ [:IDENT, 'x'],
                        [:GREATER, ' >'],
                        [:S, ' '],
                        [:IDENT, 'y']
        ], @scanner)
      end

      def test_scan_slash
        @scanner.scan('x/y')
        assert_tokens([ [:IDENT, 'x'],
                        [:SLASH, '/'],
                        [:IDENT, 'y']
        ], @scanner)
      end

      def test_scan_doubleslash
        @scanner.scan('x//y')
        assert_tokens([ [:IDENT, 'x'],
                        [:DOUBLESLASH, '//'],
                        [:IDENT, 'y']
        ], @scanner)
      end

      def test_scan_function_selector
        @scanner.scan('x:eq(0)')
        assert_tokens([ [:IDENT, 'x'],
                        [':', ':'],
                        [:FUNCTION, 'eq('],
                        [:NUMBER, "0"],
                        [")", ")"]
        ], @scanner)
      end

      def test_scan_an_plus_b
        @scanner.scan('x:nth-child(5n+3)')
        assert_tokens([ [:IDENT, 'x'],
                        [':', ':'],
                        [:FUNCTION, 'nth-child('],
                        [:NUMBER, '5'],
                        [:IDENT, 'n'],
                        [:PLUS, '+'],
                        [:NUMBER, '3'],
                        [")", ")"]
        ], @scanner)

        @scanner.scan('x:nth-child(-1n+3)')
        assert_tokens([ [:IDENT, 'x'],
                        [':', ':'],
                        [:FUNCTION, 'nth-child('],
                        [:NUMBER, '-1'],
                        [:IDENT, 'n'],
                        [:PLUS, '+'],
                        [:NUMBER, '3'],
                        [")", ")"]
        ], @scanner)

        @scanner.scan('x:nth-child(-n+3)')
        assert_tokens([ [:IDENT, 'x'],
                        [':', ':'],
                        [:FUNCTION, 'nth-child('],
                        [:IDENT, '-n'],
                        [:PLUS, '+'],
                        [:NUMBER, '3'],
                        [")", ")"]
        ], @scanner)
      end

      def assert_tokens(tokens, scanner)
        toks = []
        while tok = @scanner.next_token
          toks << tok
        end
        assert_equal(tokens, toks)
      end
    end
  end
end
