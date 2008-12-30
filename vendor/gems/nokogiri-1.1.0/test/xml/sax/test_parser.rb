require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module XML
    module SAX
      class TestParser < Nokogiri::SAX::TestCase
        def setup
          @parser = XML::SAX::Parser.new(Doc.new)
        end

        def test_parse
          File.open(XML_FILE, 'rb') { |f|
            @parser.parse(f)
          }
          @parser.parse(File.read(XML_FILE))
          assert(@parser.document.cdata_blocks.length > 0)
        end

        def test_parse_io
          File.open(XML_FILE, 'rb') { |f|
            @parser.parse_io(f)
          }
          assert(@parser.document.cdata_blocks.length > 0)
        end

        def test_parse_file
          @parser.parse_file(XML_FILE)
          assert_raises(Errno::ENOENT) {
            @parser.parse_file('')
          }
          assert_raises(Errno::EISDIR) {
            @parser.parse_file(File.expand_path(File.dirname(__FILE__)))
          }
        end

        def test_ctag
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">
              <![CDATA[ This is a comment ]]>
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.cdata_blocks
        end

        def test_comment
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.comments
        end

        def test_characters
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal ['Paragraph 1'], @parser.document.data
        end

        def test_end_document
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert @parser.document.end_document_called
        end

        def test_end_element
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal [["p"]],
            @parser.document.end_elements
        end

        def test_start_element_attrs
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal [["p", ["id", "asdfasdf"]]],
                       @parser.document.start_elements
        end

        def test_parse_document
          @parser.parse_memory(<<-eoxml)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          eoxml
        end
      end
    end
  end
end
