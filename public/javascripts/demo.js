// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

var Demo = Class.create({
  initialize: function() {
    this.body            = $(document.body);
    this.container       = $("container");
    this.footer          = $("footer");
    this.header          = $("demo_header");
    this.topContent      = $("topDemoContent");
    
    Event.observe(window, 'resize', this.resize.bind(this));
    setInterval(this.checkFontSize.bind(this), 500);
    this.resize();
  },
  
  resize: function() {
     var height = this.viewportHeight() - this.footerHeight() - this.headerHeight() - 2 /* minus padding and border size */;
     this.container.style.height = "" + height + "px";
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
  
  footerHeight: function() {
    var height = 0;
    if (this.footer) {
      height = this.footer.getHeight();
    }
    return height;
  },
  
  headerHeight: function() {
    return this.container.cumulativeOffset().top;
  },
  
  viewportHeight: function() {
    return document.viewport.getDimensions().height;
  }
});

Demo.setup = function() {
  Demo.instance = new Demo();
}

Ajax.Responders.register({
  onException: function(r, e) {
    throw e;
  }
});