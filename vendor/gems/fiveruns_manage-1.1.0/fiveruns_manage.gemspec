# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fiveruns_manage}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["FiveRuns Development Team"]
  s.date = %q{2008-11-20}
  s.default_executable = %q{fiveruns_manage}
  s.description = %q{Instrumentation for the FiveRuns Manage 2.0 product.}
  s.email = %q{dev@fiveruns.com}
  s.executables = ["fiveruns_manage"]
  s.extra_rdoc_files = ["bin/fiveruns_manage", "CHANGELOG", "lib/fiveruns/manage/plugin.rb", "lib/fiveruns/manage/reporter.rb", "lib/fiveruns/manage/targets/configuration.rb", "lib/fiveruns/manage/targets/rails/action_controller/base.rb", "lib/fiveruns/manage/targets/rails/action_controller/routing_error.rb", "lib/fiveruns/manage/targets/rails/action_mailer/base.rb", "lib/fiveruns/manage/targets/rails/action_view/base.rb", "lib/fiveruns/manage/targets/rails/action_view/partial_template.rb", "lib/fiveruns/manage/targets/rails/action_view/renderable_partial.rb", "lib/fiveruns/manage/targets/rails/active_record/active_record_error.rb", "lib/fiveruns/manage/targets/rails/active_record/base.rb", "lib/fiveruns/manage/targets/rails/cgi/session.rb", "lib/fiveruns/manage/targets/rails/mongrel/http_response.rb", "lib/fiveruns/manage/targets/rails/mongrel/http_server.rb", "lib/fiveruns/manage/targets/rails.rb", "lib/fiveruns/manage/targets/target.rb", "lib/fiveruns/manage/targets.rb", "lib/fiveruns/manage/version.rb", "lib/fiveruns/manage.rb", "lib/fiveruns_manage.rb", "README.rdoc"]
  s.files = ["bin/fiveruns_manage", "CHANGELOG", "init.rb", "lib/fiveruns/manage/plugin.rb", "lib/fiveruns/manage/reporter.rb", "lib/fiveruns/manage/targets/configuration.rb", "lib/fiveruns/manage/targets/rails/action_controller/base.rb", "lib/fiveruns/manage/targets/rails/action_controller/routing_error.rb", "lib/fiveruns/manage/targets/rails/action_mailer/base.rb", "lib/fiveruns/manage/targets/rails/action_view/base.rb", "lib/fiveruns/manage/targets/rails/action_view/partial_template.rb", "lib/fiveruns/manage/targets/rails/action_view/renderable_partial.rb", "lib/fiveruns/manage/targets/rails/active_record/active_record_error.rb", "lib/fiveruns/manage/targets/rails/active_record/base.rb", "lib/fiveruns/manage/targets/rails/cgi/session.rb", "lib/fiveruns/manage/targets/rails/mongrel/http_response.rb", "lib/fiveruns/manage/targets/rails/mongrel/http_server.rb", "lib/fiveruns/manage/targets/rails.rb", "lib/fiveruns/manage/targets/target.rb", "lib/fiveruns/manage/targets.rb", "lib/fiveruns/manage/version.rb", "lib/fiveruns/manage.rb", "lib/fiveruns_manage.rb", "Manifest", "rails/init.rb", "Rakefile", "README.rdoc", "test/target_test.rb", "test/targets/rails.rb", "test/test_helper.rb", "fiveruns_manage.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/fiveruns/fiveruns_manage}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Fiveruns_manage", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{fiveruns}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Instrumentation for the FiveRuns Manage 2.0 product.}
  s.test_files = ["test/target_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
