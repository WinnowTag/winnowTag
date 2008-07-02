// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
Effect.ScrollToInDiv = Class.create(Effect.Base, {
  initialize: function(container, element) {
    this.container = $(container);
    this.element = $(element);
    this.bottom_margin = (arguments[2] && arguments[2].bottom_margin) || 0;
    this.start(arguments[2] || {});      
  },
  setup: function() {
    var containerOffset = Position.cumulativeOffset(this.container);
    var offsets = Position.cumulativeOffset(this.element);
    if(this.options.offset) {
      offsets[1] += this.options.offset;
    }

    this.scrollStart = this.container.scrollTop;
     var top_of_element = offsets[1] - this.scrollStart;
     var top_of_container = containerOffset[1];
     var bottom_of_element = offsets[1] + this.element.getHeight() - this.scrollStart;
     var bottom_of_container = containerOffset[1] + this.container.getHeight();
     
     // If the item is above the top of the container, or the item is taller than the container, scroll to the top of the item
     if(top_of_element < top_of_container || this.element.getHeight() > this.container.getHeight()) {
       this.delta = top_of_element - top_of_container;

     // If the item is below the bottom of the container, scroll to the bottom of the item
     } else if(bottom_of_element > bottom_of_container) {
       this.delta = bottom_of_element - bottom_of_container + this.bottom_margin;

     } else {
       this.delta = 0;
     }
  },
  update: function(factor) {
    this.container.scrollTop = this.scrollStart + (factor * this.delta);
  }
});