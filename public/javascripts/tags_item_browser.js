// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var TagsItemBrowser = Class.create(ItemBrowser, {
  initializeTag: function(tag) {
    tag = $(tag);

    var summary = tag.down(".summary");
    var extended = tag.down(".extended");
    var comments = extended.down(".comments");
    summary.observe("click", function(event) {
      if(["a", "input", "textarea"].include(event.element().tagName.toLowerCase())) { return; }

      extended.toggle();
      comments.load(function() {
        tag.down(".summary .comments .unread_comments").update("0");
      }.bind(this));
      var slider = tag.down(".slider");
      if(!slider.bias_slider) {
        slider.bias_slider = new BiasSlider(slider);
      }
    }.bind(this));
  },
  
  insertItem: function($super, item_id, content) {
    $super(item_id, content);
    this.initializeTag(item_id);
  }
});