####
# Copyright (c) 2007 RightScale, Inc, All Rights Reserved Worldwide.
#
# THIS PROGRAM IS CONFIDENTIAL AND PROPRIETARY TO RIGHTSCALE
# AND CONSTITUTES A VALUABLE TRADE SECRET.  Any unauthorized use,
# reproduction, modification, or disclosure of this program is
# strictly prohibited.  Any use of this program by an authorized
# licensee is strictly subject to the terms and conditions,
# including confidentiality obligations, set forth in the applicable
# License Agreement between RightScale.com, Inc. and
# the licensee.
#
# Handler for status/health checks.
# Load balancers (or other machines for that matter) will be able to monitor the health of
# each mongrel by retrieving a successful response from this handler
# This file can be included in the configuration of the mongrels (i.e., mongrel_cluster.yml)
# config_script: lib/mongrel_health_check_handler.rb
#
# Josep M. Blanquer
# August 30, 2007
#

# This must be called from a Mongrel configuration...
class MongrelHealthCheckHandler < Mongrel::HttpHandler
  def initialize
    #Make sure it's expired by the time we process the first request
    @DB_OK_at= Time.at(0)
    @freshness= 30
    @error_msg=""
  end
  def process(request,response)
    
    # Write down if it's time to do a more heavyweight check 
    db_stale=true if( (Time.now()-@DB_OK_at).to_i > @freshness )
    
    check_db if db_stale
    
    code = ( (Time.now()-@DB_OK_at).to_i > @freshness )? 500:200
    # Return OK if ActiveRecord is not connected yet (i.e., test mongrel only)
    code = 200 unless ActiveRecord::Base.connected?
    
    response.start(code) do |head,out|
      head["Content-Type"] = "text/html"
      
      t = Time.now()
      out.write "Now: #{t} , DB OK #{(t-@DB_OK_at).to_i}s ago\n"
      out.write "ERROR:#{@error_msg}" if @error_msg != ""
    end
  end
  
  # Check health of DB, and update the @DB_OK_at timestamp if it succeeds 
  def check_db
    if ActiveRecord::Base.connected?
      begin      
        ActiveRecord::Base.connection.verify!(0) #verify now (and reconnect if necessary) 
        ActiveRecord::Base.connection.select_value("SELECT NOW()")
        @DB_OK_at = Time.now
        @error_msg = ""
      rescue Exception => e
        # Do your logging/error handling here
        @error_msg = e.inspect
      end
    end 
  end
end

uri "/mongrel-status", :handler => MongrelHealthCheckHandler.new, :in_front => true
