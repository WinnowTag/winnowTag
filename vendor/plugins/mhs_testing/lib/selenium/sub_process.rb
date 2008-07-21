module Selenium
  class SubProcess
    attr_accessor :pid
    
    def initialize command = nil, environment = {}
      @command, @environment = command, environment
    end
    
    def start
      env = @environment.map { |k,v| "#{k}=#{v}" }.join(" ")
      system "#{env} #{@command} 1> /dev/null 2> /dev/null &"
      find
      sleep 5
    end

    def stop
      Process.kill 15, @pid
    end
    
    def find
      result = `ps -e -o pid,command`.split(/\s*\n\s*/).grep(/#{Regexp.escape(@command)}/).first
      @pid = result.to_i if result
    end

    def self.start(*args)
      process = new(*args)
      process.start
      process
    end
    
    def self.find(command)
      process = new(command)
      if process.find
        process
      end
    end
  end
end
