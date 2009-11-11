// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

var Folder = Class.create({
  
  initialize: function(folder) {
    this.folder = folder;
    Droppables.add(this.folder, {
      accept: ['feed', 'tag'],
      hoverclass: 'hover',
      onDrop: function(element, folder) {
        if (folder.down('#' + element.getAttribute('id'))) {
          return;
        }
        folder.addClassName('open');
        Cookie.set(this.folder.id, true, 365);
        new Ajax.Request(this.folder.getAttribute('data-add_item_url'), {
          asynchronous: true,
          evalScripts: true,
          method: 'put',
          parameters: 'item_id=' + encodeURIComponent(element.id)
        });
      }.bind(this)
    });
  }
});

document.observe('sidebar:loaded', function() {
  $$("#sidebar .folder").each(function(folder) {
    new Folder(folder);
  });
});
