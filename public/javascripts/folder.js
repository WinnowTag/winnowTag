// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

var Folder = Class.create({
  
  initialize: function(folder) {
    this.folder = folder;

    Droppables.add(this.folder, {
      accept: ['feed', 'tag'], hoverclass: 'hover',
      onDrop: function(element, folder) {
        this.open();

        var selected = element.up(".multidrag").select('.selected');
        selected.each(this.addItem.bind(this));
      }.bind(this)
    });
  },
  
  open: function() {
    this.folder.addClassName('open');
    Cookie.set(this.folder.id, true, 365);
  },
  
  addItem: function(tag_or_feed) {
    if(this.folder.down('#' + tag_or_feed.getAttribute('id'))) { return; }
    
    new Ajax.Request(this.folder.getAttribute('data-add_item_url'), {
      method: 'put', evalScripts: true,
      parameters: 'item_id=' + encodeURIComponent(tag_or_feed.id)
    });
  }
});

document.observe('sidebar:loaded', function() {
  $$("#sidebar .folder").each(function(folder) {
    new Folder(folder);
  });
});
