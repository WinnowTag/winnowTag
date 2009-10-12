ActionView::Helpers::AssetTagHelper.register_javascript_expansion :winnow => [
  "slider", "element", "cookies", "bias_slider", "timeout", "messages", "placeholder", 
  "scroll", "classification", "item_browser", "feed_items_item_browser", "tags_item_browser", "item", 
  "sidebar", "sidebar_section", "content", "feedback", "login", "tag_filter", "single_submit_form"
]

ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :winnow => [
  "defaults", "button", "winnow", "tables", "slider", "scaffold"
]
