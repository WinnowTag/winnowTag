// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var AppleSearch = Class.create({
  initialize: function(element) {
    this.element = element;
    this.element.addClassName("non_safari");
    this.element.applesearch = this;

    this.text_input = element.down("input");
    this.text_input.observe("keyup", this.updateClearButton.bind(this));
    this.text_input.observe("focus", this.removePlaceholder.bind(this));
    this.text_input.observe("blur", function() {
      this.updateClearButton();
      this.insertPlaceholder();
    }.bind(this));
    this.text_input.observe("applesearch:blur", function() {
      this.updateClearButton();
      this.insertPlaceholder();
    }.bind(this));
    this.text_input.observe("applesearch:setup", function() {
      this.updateClearButton();
      this.removePlaceholder();
    }.bind(this));

    this.clear_button = element.down('.srch_clear');
    this.clear_button.observe("click", this.clear.bind(this));
    
    this.updateClearButton();
    this.insertPlaceholder();
  },

  updateClearButton: function() {
    if(this.text_input.value.length > 0) {
      this.clear_button.addClassName("clear_button");
    } else {
      this.clear_button.removeClassName("clear_button");
    }
  },
  
  clear: function () {
    this.text_input.value = "";
    this.updateClearButton();
    this.text_input.focus();
  },

  insertPlaceholder: function() {
    if(this.text_input.value == "") {
      this.text_input.addClassName("placeholder");
      this.text_input.value = this.text_input.getAttribute("placeholder");
    }
  },

  removePlaceholder: function() {
    if(this.text_input.value == this.text_input.getAttribute("placeholder")) {
      this.text_input.value = "";
    }
    this.text_input.removeClassName("placeholder");
  }
});

AppleSearch.setup = function() {
  if(navigator.userAgent.toLowerCase().indexOf('safari') >= 0) { return; }
  
  $$(".applesearch").each(function(element) {
    new AppleSearch(element);
  });
};
