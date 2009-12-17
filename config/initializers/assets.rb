ActionView::Helpers::AssetTagHelper.register_javascript_expansion :winnow => [
  "slider", "element", "cookies", "bias_slider", "timeout", "messages", "labeled_input", "placeholder", 
  "scroll", "classification", "item_browser", "feed_items_item_browser", "tags_item_browser", "item", 
  "sidebar", "sidebar_section", "content", "feedback", "login", "tag_filter", "single_submit_form", "folder"
]

ActionView::Helpers::AssetTagHelper.register_javascript_expansion :demo => [
  "item_browser", "scroll", "demo", "feed_items_item_browser", "cookies", "item", "element"
]

ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :winnow => [
  "defaults", "button", "winnow", "tables", "slider", "scaffold", "record", "feed_item"
]

ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :demo => [
  "defaults", "button", "demo", "tables", "slider", "scaffold", "record", "feed_item"
]