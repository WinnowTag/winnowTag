# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require 'active_resource/connection'
require 'action_mailer/adv_attr_accessor'

module ActiveResource
  class InvalidRequestError < StandardError; end

  class BetterHttpMock
    class << self
      def definitions
        @@definitions ||= {}
      end

      def define(name)
        definitions[name] = [ActiveResource::Request.new, ActiveResource::Response.new]
        yield *definitions[name]
        # TODO: Require request.method and request.path
      end

      def recordings
        @@recordings ||= []
      end
      
      def record(method, path, body, headers)
        recordings << ActiveResource::Request.new(method, path, body, headers)
        recordings.last
      end
      
      def execute(method, path, body, headers)
        request = record(method, path, body, headers)

        name, (defined_request, defined_response) = definitions.detect { |name, (defined_request, defined_response)| defined_request == request }
        
        if defined_request && defined_response
          defined_request.execute!
          defined_response
        else
          raise InvalidRequestError.new("No response recorded for #{request}")
        end
      end
      
      def has_executed?(name)
        definitions[name].first.executed?
      end
    end

    for method in [ :post, :put ]
      module_eval <<-EOE, __FILE__, __LINE__
        def #{method}(path, body, headers)
          self.class.execute(:#{method}, path, body, headers)
        end
      EOE
    end

    for method in [ :get, :delete, :head ]
      module_eval <<-EOE, __FILE__, __LINE__
        def #{method}(path, headers)
          self.class.execute(:#{method}, path, nil, headers)
        end
      EOE
    end

    def initialize(site) #:nodoc:
      @site = site
    end
  end

  class Request
    include ActionMailer::AdvAttrAccessor
    
    adv_attr_accessor :method, :path, :body, :headers

    def initialize(method = nil, path = nil, body = nil, headers = {})
      @method, @path, @body, @headers = method, path, body, headers.merge(ActiveResource::Connection::HTTP_FORMAT_HEADER_NAMES[method] => 'application/xml')
      @executed = false
    end

    def ==(other)
      other.method == method && other.path == path && other.body == body && headers_match?(other)
    end
    
    def headers_match?(other)
      headers.keys.sort == other.headers.keys.sort && headers.all? do |key, value|
        if value.is_a?(Regexp)
          value =~ other.headers[key] ? true : false
        else
          value == other.headers[key]
        end
      end
    end
    
    def executed?
      @executed
    end
    
    def execute!
      @executed = true
    end
    
    def to_s
      "<#{method.to_s.upcase}: #{path} [#{headers.inspect}] (#{body})>"
    end
  end

  class Response
    include ActionMailer::AdvAttrAccessor
    
    adv_attr_accessor :body, :message, :code, :headers

    def initialize(body = nil, message = 200, headers = {})
      @body, @message, @headers = body, message.to_s, headers
      @code = @message[0,3].to_i

      resp_cls = Net::HTTPResponse::CODE_TO_OBJ[@code.to_s]
      if resp_cls && !resp_cls.body_permitted?
        @body = nil
      end

      if @body.nil?
        self['Content-Length'] = "0"
      else
        self['Content-Length'] = body.size.to_s
      end
    end

    def success?
      (200..299).include?(code)
    end
    
    def [](key)
      headers[key]
    end
    
    def []=(key, value)
      headers[key] = value
    end

    def ==(other)
      other.body == body && other.message == message && other.headers == headers
    end
  end

  class Connection
    private
      silence_warnings do
        def http
          @http ||= BetterHttpMock.new(@site)
        end
      end
  end
end
