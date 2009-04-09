// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var SidebarSection = Class.create({
  initialize: function(element) {
    this.element = element;
    
    this.toggle_button = element.down('.toggle_button');
    this.toggle_button.observe("click", function(){
      this.toggleOpen();
      this.setOpenCookie();
    }.bind(this));
    
    this.add_link = element.down('.add_link');
    this.add_link.observe("click", this.add.bind(this));
    
    this.edit_link = element.down('.edit_link');
    this.edit_link.observe("click", this.edit.bind(this));
    
    this.cancel_link = element.down('.cancel_link');
    this.cancel_link.observe("click", this.cancel.bind(this));
    
    this.input = element.down('.add_form input');
  },
  
  toggleOpen: function() {
    this.element.toggleClassName('open');
    this.cancel();
  },
  
  setOpenCookie: function() {
    Cookie.set(this.element.id, this.element.hasClassName('open'), 365);
  },
  
  add: function() {
    this.element.addClassName('open');
    this.element.addClassName('add');
    this.input.focus();
  },
  
  edit: function() {
    this.element.addClassName('open');
    this.element.toggleClassName('edit');
  },
  
  cancel: function() {
    this.element.removeClassName('add');
    this.element.removeClassName('edit');
    this.input.clear();
  }
});
