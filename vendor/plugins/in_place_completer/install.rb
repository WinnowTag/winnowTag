# Install hook code here

require 'fileutils'

FileUtils.cp(File.join(File.dirname(__FILE__),"files","in_place_completer.js"),File.join(File.dirname(__FILE__),"..","..","..","public","javascripts"))
