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
    this.sidebar         = $("sidebar");
    this.sidebar_control = $("sidebar_control");
    
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
    this.resizeWidth();
    this.resizeHeight();
    this.resizeSidebar();
  },
  
  resizeHeight: function() {
    this.content.style.height = this.contentHeight() + 'px';
  },
  
  resizeWidth: function() {
    this.container.style.width = this.contentWidth() + 'px';
  },
  
  resizeSidebar: function() {
    if(this.sidebar) {
      this.sidebar.style.height = this.sidebarHeight() + 'px';
    }
    if(this.sidebar_control) {
      this.sidebar_control.style.height = this.sidebarControlHeight() + 'px';
    }
  },
  
  contentHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_content = this.content.offsetTop;
    var content_padding = parseInt(this.content.getStyle("padding-top")) + parseInt(this.content.getStyle("padding-bottom"));
    var footer_height = this.footer ? this.footer.getHeight() : 0;

    return body_height - top_of_content - content_padding - footer_height;
  },
  
  contentWidth: function() {
    var body_width = this.body.getWidth();

    var sidebar_width = 0;
    if(this.sidebar && this.sidebar.visible()) {
      sidebar_width = this.sidebar.getWidth();
    }
    
    var sidebar_control_width = 0;
    if(this.sidebar_control) {
      sidebar_control_width = this.sidebar_control.getWidth();
    }
    
    var extra = 0;
    if(Prototype.Browser.Gecko) {
      // sometimes firefox is just a little off, this keeps the content visible
      extra = 0.25;
    }

    return body_width - sidebar_width - sidebar_control_width - extra;
  },
  
  sidebarHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_sidebar = this.sidebar.offsetTop;
    
    return body_height - top_of_sidebar;
  },
  
  sidebarControlHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_sidebar_control = this.sidebar_control.offsetTop;

    return body_height - top_of_sidebar_control;
  }
});

// Sets up the one instance of this class, through which other functions
// interact with it.
Content.setup = function() {
  Content.instance = new Content();
}
