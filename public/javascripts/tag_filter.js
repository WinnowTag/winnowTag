// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

// Handles renaming a tag in the tags section of the sidebard on the items page.
// An instance of this class is created for each tag.
var TagFilter = Class.create({
  initialize: function(element) {
    this.tag = element;
    this.editLink = this.tag.down('.edit');
    if (this.editLink) {
      this.editLink.observe('click', this.editTag.bind(this));
    }
  },
  
  editTag: function() {
    var new_tag_name = prompt('Tag Name:', this.tag.down('.name').innerHTML.unescapeHTML());
    if(new_tag_name) {
      this.renameTag(new_tag_name);
    }
  },
  
  renameTag: function(newName) {
    new Ajax.Request(this.editLink.getAttribute('data-update_url'), {
      parameters: { 'tag[name]': newName },
      method: 'put',
      requestHeaders: { Accept: 'application/json' },
      onSuccess: function(response) {
        var data = response.responseJSON;
        $$("." + this.tag.id).each(function(e) {
          e.down('.name').update(data.name);
          e.up().insertInOrder('.name', e, data.name);
        });
      }.bind(this)
    });
  }
});