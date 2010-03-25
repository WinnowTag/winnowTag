// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

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
    
    Event.observe(window, 'resize', this.resize.bind(this));
    setInterval(this.checkFontSize.bind(this), 500);
    this.resize();
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
