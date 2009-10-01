require 'nokogiri'

module XSD # :nodoc:
  module XMLParser # :nodoc:
    ###
    # Nokogiri XML parser for soap4r.
    #
    # Nokogiri may be used as the XML parser in soap4r.  Simply require
    # 'xsd/xmlparser/nokogiri' in your soap4r applications, and soap4r
    # will use Nokogiri as it's XML parser.  No other changes should be
    # required to use Nokogiri as the XML parser.
    #
    # Example (using UW ITS Web Services):
    #
    #   require 'rubygems'
    #   require 'nokogiri'
    #   gem 'soap4r'
    #   require 'defaultDriver'
    #   require 'xsd/xmlparser/nokogiri'
    #   
    #   obj = AvlPortType.new
    #   obj.getLatestByRoute(obj.getAgencies.first, 8).each do |bus|
    #     p "#{bus.routeID}, #{bus.longitude}, #{bus.latitude}"
    #   end
    #
    class Nokogiri < XSD::XMLParser::Parser
      ###
      # Create a new XSD parser with +host+ and +opt+
      def initialize host, opt = {}
        super
        @parser = ::Nokogiri::XML::SAX::Parser.new(self, @charset || 'UTF-8')
      end

      ###
      # Start parsing +string_or_readable+
      def do_parse string_or_readable
        @parser.parse(string_or_readable)
      end

      ###
      # Handle the start_element event with +name+ and +attrs+
      def start_element name, attrs = []
        super(name, Hash[*attrs.flatten])
      end

      ###
      # Handle the end_element event with +name+
      def end_element name
        super
      end

      ###
      # Handle errors with message +msg+
      def error msg
        raise ParseError.new(msg)
      end
      alias :warning :error

      ###
      # Handle cdata_blocks containing +string+
      def cdata_block string
        characters string
      end

      %w{ start_document start_element_namespace end_element_namespace end_document comment }.each do |name|
        class_eval %{ def #{name}(*args); end }
      end
      add_factory(self)
    end
  end
end
