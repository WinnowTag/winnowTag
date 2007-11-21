module Spec
  module Example
    class Example
      PENDING_EXAMPLE_BLOCK = lambda {
        raise Spec::Example::ExamplePendingError.new("Not Yet Implemented")
      }
      attr_accessor :description
      attr_reader :from, :method_name

      def initialize(description, method_name)
        @from = caller(0)[3]
        @method_name = method_name
        @description = description
      end
      
      def to_s
        description
      end
    end
  end
end
