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
    
    var nameToEdit = tag.down("#name_" + tag.id);
    if (nameToEdit) {
      new Ajax.InPlaceEditor(
        nameToEdit,
        nameToEdit.getAttribute("data-update_url"),
        {
          ajaxOptions: {
            method: 'put',
            requestHeaders: { Accept: 'application/json' },
            onSuccess: function(response) {
              var data = response.responseJSON;
              tag.select('.name').invoke('update', data.name);
              tag.down(".feed_links").update(data.feed_links_content);
              tag.up().insertInOrder('.name', tag, data.name);
            }.bind(this)
          },
          paramName: 'tag[name]',
          htmlResponse: false,
          clickToEditText: I18n.t("winnow.tags.main.click_to_edit_name"),
          okText: I18n.t("winnow.general.save")
        }
      );
    }
  },
  
  insertItem: function($super, item_id, content) {
    $super(item_id, content);
    this.initializeTag(item_id);
  }
});