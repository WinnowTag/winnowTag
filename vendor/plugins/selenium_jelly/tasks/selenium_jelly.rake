namespace :spec do
  rspec_base = File.expand_path(File.join(RAILS_ROOT, *%w[vendor plugins rspec lib]))
  $LOAD_PATH.unshift(rspec_base) if File.exist?(rspec_base)
  require 'spec/rake/spectask'
  require 'spec/translator'
  spec_prereq = File.exist?(File.join(RAILS_ROOT, 'config', 'database.yml')) ? "test:db:initialize" : :noop

  desc "Run the specs under spec/selenium"
  Spec::Rake::SpecTask.new(:selenium => spec_prereq) do |t|
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList["spec/selenium/**/*_spec.rb"]
  end
end