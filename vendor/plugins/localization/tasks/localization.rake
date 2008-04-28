namespace :localization do
  def used
    require 'active_support'
    keys = {}
    Dir["app/**/*"].each do |file|
      next if File.directory?(file)
      File.read(file).scan(/_\(:(\w+)[),]/).flatten.each do |key|
        keys[key] ||= []
        keys[key] << file
      end
    end
    keys
  end
  
  def defined
    Localization.mappings.keys.map(&:to_s)
  end
  
  task :used do
    require 'colored'
    used.sort.each do |key, files|
      puts "#{key.bold} (#{files.size})", "\t#{files.join("\n\t")}"
    end
  end
  
  task :undefined => :environment do
    require 'colored'
    used.delete_if { |k,v| defined.include?(k) }.sort.each do |key, files|
      puts "#{key.bold} (#{files.size})", "\t#{files.join("\n\t")}"
    end
  end
  
  task :unused => :environment do
    require 'colored'
    (defined - used.keys).each do |key|
      puts key.bold
    end
  end
  
  task :check do
    Rake::Task["localization:undefined"].invoke
    Rake::Task["localization:unused"].invoke
  end
end