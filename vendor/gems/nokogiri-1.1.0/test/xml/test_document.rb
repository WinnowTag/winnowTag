require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDocument < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_XML_function
        xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        assert xml.xml?
      end

      def test_document_parent
        xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        assert_raises(NoMethodError) {
          xml.parent
        }
      end

      def test_document_name
        xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        assert_equal 'document', xml.name
      end

      def test_parse_can_take_io
        xml = nil
        File.open(XML_FILE, 'rb') { |f|
          xml = Nokogiri::XML(f)
        }
        assert xml.xml?
        set = xml.search('//employee')
        assert set.length > 0
      end

      def test_search_on_empty_documents
        doc = Nokogiri::XML::Document.new
        ns = doc.search('//foo')
        assert_equal 0, ns.length
      end

      def test_bad_xpath_raises_syntax_error
        assert_raises(XML::XPath::SyntaxError) {
          @xml.xpath('\\')
        }
      end

      def test_new_document_collect_namespaces
        doc = Nokogiri::XML::Document.new
        assert_equal({}, doc.collect_namespaces)
      end

      def test_find_with_namespace
        doc = Nokogiri::XML.parse(<<-eoxml)
        <x xmlns:tenderlove='http://tenderlovemaking.com/'>
          <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
        </x>
        eoxml

        ctx = Nokogiri::XML::XPathContext.new(doc)
        ctx.register_ns 'tenderlove', 'http://tenderlovemaking.com/'
        set = ctx.evaluate('//tenderlove:foo').node_set
        assert_equal 1, set.length
        assert_equal 'foo', set.first.name

        # It looks like only the URI is important:
        ctx = Nokogiri::XML::XPathContext.new(doc)
        ctx.register_ns 'america', 'http://tenderlovemaking.com/'
        set = ctx.evaluate('//america:foo').node_set
        assert_equal 1, set.length
        assert_equal 'foo', set.first.name

        # Its so important that a missing slash will cause it to return nothing
        ctx = Nokogiri::XML::XPathContext.new(doc)
        ctx.register_ns 'america', 'http://tenderlovemaking.com'
        set = ctx.evaluate('//america:foo').node_set
        assert_equal 0, set.length
      end

      def test_xml?
        assert @xml.xml?
      end

      def test_document
        assert @xml.document
      end

      def test_singleton_methods
        assert node_set = @xml.search('//name')
        assert node_set.length > 0
        node = node_set.first
        def node.test
          'test'
        end
        assert node_set = @xml.search('//name')
        assert_equal 'test', node_set.first.test
      end

      def test_multiple_search
        assert node_set = @xml.search('//employee', '//name')
        employees = @xml.search('//employee')
        names = @xml.search('//name')
        assert_equal(employees.length + names.length, node_set.length)
      end

      def test_node_set_index
        assert node_set = @xml.search('//employee')

        assert_equal(5, node_set.length)
        assert node_set[4]
        assert_nil node_set[5]
      end

      def test_search
        assert node_set = @xml.search('//employee')

        assert_equal(5, node_set.length)

        node_set.each do |node|
          assert_equal('employee', node.name)
        end
      end

      def test_dump
        assert @xml.serialize
        assert @xml.to_xml
      end

      def test_subset_is_decorated
        x = Module.new do
          def awesome!
          end
        end
        util_decorate(@xml, x)

        assert @xml.respond_to?(:awesome!)
        assert node_set = @xml.search('//staff')
        assert node_set.respond_to?(:awesome!)
        assert subset = node_set.search('.//employee')
        assert subset.respond_to?(:awesome!)
        assert sub_subset = node_set.search('.//name')
        assert sub_subset.respond_to?(:awesome!)
      end

      def test_decorator_is_applied
        x = Module.new do
          def awesome!
          end
        end
        util_decorate(@xml, x)

        assert @xml.respond_to?(:awesome!)
        assert node_set = @xml.search('//employee')
        assert node_set.respond_to?(:awesome!)
        node_set.each do |node|
          assert node.respond_to?(:awesome!), node.class
        end
        assert @xml.root.respond_to?(:awesome!)
      end

      def test_new
        doc = nil
        assert_nothing_raised {
          doc = Nokogiri::XML::Document.new
        }
        assert doc
        assert doc.xml?
        assert_nil doc.root
      end

      def test_set_root
        doc = nil
        assert_nothing_raised {
          doc = Nokogiri::XML::Document.new
        }
        assert doc
        assert doc.xml?
        assert_nil doc.root
        node = Nokogiri::XML::Node.new("b", doc) { |n|
          n.content = 'hello world'
        }
        assert_equal('hello world', node.content)
        doc.root = node
        assert_equal(node, doc.root)
      end

      def util_decorate(document, x)
        document.decorators(XML::Node) << x
        document.decorators(XML::NodeSet) << x
        document.decorate!
      end
    end
  end
end
