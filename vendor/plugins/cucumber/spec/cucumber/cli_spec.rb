require File.dirname(__FILE__) + '/../spec_helper'
require 'yaml'

module Cucumber
  describe CLI do
    it "should expand args from YAML file" do
      cli = CLI.new

      cucumber_yml = {'bongo' => '--require from/yml'}.to_yaml
      IO.should_receive(:read).with('cucumber.yml').and_return(cucumber_yml)

      cli.parse_options!(%w{--format progress --profile bongo})
      cli.options.should == {
        :format => 'progress',
        :require => ['from/yml'], 
        :dry_run => false, 
        :lang => 'en',
        :source => true,
        :out => STDOUT
      }
    end

    it "should expand args from YAML file's default if there are no args" do
      cli = CLI.new

      cucumber_yml = {'default' => '--require from/yml'}.to_yaml
      IO.should_receive(:read).with('cucumber.yml').and_return(cucumber_yml)

      cli.parse_options!([])
      cli.options.should == {
        :format => 'pretty',
        :require => ['from/yml'], 
        :dry_run => false, 
        :lang => 'en',
        :source => true,
        :out => STDOUT
      }
    end
    
    it "should accept --no-source option" do
      cli = CLI.new
      cli.parse_options!(%w{--no-source})
      
      cli.options[:source].should be_false
    end

    it "should accept --out option" do
      cli = CLI.new
      File.should_receive(:open).with('jalla.txt', 'w')
      cli.parse_options!(%w{--out jalla.txt})
    end
        
  end
end