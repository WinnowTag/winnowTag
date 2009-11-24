# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
namespace :assets do
  task :clean => :environment do
    joined_javascript_path = File.join(ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR, "all.js")
    joined_stylesheet_path = File.join(ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR, "all.css")
    [joined_javascript_path, joined_stylesheet_path].each do |path|
      File.delete(path) if File.exist?(path)
    end
  end
end
