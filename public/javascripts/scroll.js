// General info: http://doc.winnowtag.org/open-source
// Source code repository: http://github.com/winnowtag
// Questions and feedback: contact@winnowtag.org
//
// Copyright (c) 2007-2011 The Kaphan Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


// Custome Effect class that will move an item into view if it is partly
// hidden. Used on the items page when selecting an item, showing an item
// body, showing other item details, and loading the list of items.
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