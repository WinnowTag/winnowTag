# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# TODO: Get this merged into Rails. It is only patched locally right now.
# namespace :gems do
#   task :build => :base do
#     require 'rails/gem_builder'
#     gems_to_build = Rails.configuration.gems + Rails.configuration.gems.map { |gem| gem.dependencies }.flatten
#     gems_to_build.uniq.each do |gem|
#       next unless gem.frozen? && (ENV['GEM'].blank? || ENV['GEM'] == gem.name)
#       gem_dir = gem.gem_dir(Rails::GemDependency.unpacked_path)
#       spec_file = File.join(gem_dir, '.specification')
#       specification = YAML::load_file(spec_file)
#       Rails::GemBuilder.new(specification, gem_dir).build_extensions
#       puts "Built gem: '#{gem_dir}'"
#     end
#   end
# end