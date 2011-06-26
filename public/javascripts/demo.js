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


var Demo = Class.create({
  initialize: function() {
    this.body            = $(document.body);
    this.container       = $("container");
    this.footer          = $("footer");
    this.header          = $("demo_header");
    this.topContent      = $("topDemoContent");
    this.queuedScroll    = 0;
    
    Event.observe(window, 'resize', this.resizeEventHandler.bind(this));
    setInterval(this.checkFontSize.bind(this), 500);
    this.resize();
    this.scrollSelectedTagIntoView.defer();
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
     var height = this.viewportHeight() - this.footerHeight() - this.headerHeight() - 1;
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