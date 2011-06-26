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


// This class manages the area in which various items are shown. It handles
// resizing the height and width in response to the number of items shown
// and/or the user hiding/showing various parts of the UI.
//
// This class is intended to be a Singleton. Its one instance is created in
// its setup() function, which is called when the DOM is loaded (currently
// observed in the main application layout).
var Content = Class.create({
  initialize: function() {
    this.body            = $(document.body);
    this.container       = $("container");
    this.content         = $("content");
    this.footer          = $("footer");
    this.messages        = $("messages");
    this.queuedScroll    = 0;
    
    Event.observe(window, 'resize', this.resizeEventHandler.bind(this));
    setInterval(this.checkFontSize.bind(this), 500);
    this.resize();
    this.scrollSelectedTagIntoView.defer();
  },

  checkFontSize: function() {
    if(/MSIE/.test(navigator.userAgent)) {
      // TODO: Figure out an IE solution
    } else {
  		var currentFontSize = window.getComputedStyle(document.documentElement, null).fontSize;
  		if(!this.lastFontSize || currentFontSize != this.lastFontSize) {
  			this.lastFontSize = currentFontSize;
        this.resize();
  		}
    }
  },
  
  scrollSelectedTagIntoView: function() {
    if (typeof itemBrowser != 'undefined')
      itemBrowser.scrollSelectedTagIntoView();
  },

  resizeEventHandler: function() {
    this.resize();
    window.clearTimeout(this.queuedScroll);
    this.queuedScroll = this.scrollSelectedTagIntoView.delay(1);
  },

  resize: function() {
    var newHeight = this.containerHeight();
    // IE does some stupid things in the middle of resize events,
    // so this prevents a JS error when the content height is negative.
    if (newHeight > 0) {
      this.container.style.height = newHeight + 'px';
    }
  },
  
  containerHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_content = this.content.offsetTop;
    var content_padding = parseInt(this.content.getStyle("padding-top")) + parseInt(this.content.getStyle("padding-bottom"));
    var footer_height = this.footer ? this.footer.getHeight() : 0;
    return body_height - top_of_content - content_padding - footer_height;
  }
});

// Sets up the one instance of this class, through which other functions
// interact with it.
Content.setup = function() {
  Content.instance = new Content();
}
