require 'tzinfo/timezone_definition'

module TZInfo
  module Definitions
    module Pacific
      module Yap
        include TimezoneDefinition
        
        linked_timezone 'Pacific/Yap', 'Pacific/Truk'
      end
    end
  end
end
