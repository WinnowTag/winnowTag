// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Content = Class.create({
  initialize: function() {
    this.body            = document.body;
    this.container       = $("container");
    this.content         = $("content");
    this.footer          = $("footer");
    this.messages        = $("messages");
    this.sidebar         = $("sidebar");
    this.sidebar_control = $("sidebar_control");
    
    Event.observe(window, 'resize', this.resize.bind(this));
		setInterval(this.checkFontSize.bind(this), 500);
  },
  
  checkFontSize: function() {
		var currentFontSize = window.getComputedStyle(document.documentElement, null).fontSize;
		if(!this.lastFontSize || currentFontSize != this.lastFontSize) {
			this.lastFontSize = currentFontSize;
      this.resize();
		}
  },
  
  resize: function() {
    this.resizeHeight();
    this.resizeWidth();
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
    var container_padding = parseInt(this.container.getStyle("padding-top")) + parseInt(this.container.getStyle("padding-bottom"));
    var messages_height = 0; // this.messages.visible() ? this.messages.getHeight() : 0;
    
    return body_height - top_of_content - footer_height - content_padding - container_padding - messages_height + 2;
  },
  
  contentWidth: function() {
    var body_width = this.body.getWidth();

    var sidebar_width = 0, sidebar_margin = 0;
    if(this.sidebar && this.sidebar.visible()) {
      sidebar_width = this.sidebar.getWidth();
      sidebar_margin = parseInt(this.sidebar.getStyle("margin-left")) + parseInt(this.sidebar.getStyle("margin-right"));
    }
    
    var sidebar_control_width = 0, sidebar_control_margin = 0;
    if(this.sidebar_control) {
      sidebar_control_width = this.sidebar_control.getWidth();
      sidebar_control_margin = parseInt(this.sidebar_control.getStyle("margin-left")) + parseInt(this.sidebar_control.getStyle("margin-right"));
    }

    return body_width - sidebar_width - sidebar_margin - sidebar_control_width - sidebar_control_margin - 7;
  },
  
  sidebarHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_content = this.content.offsetTop;
    var sidebar_padding = parseInt(this.sidebar.getStyle("padding-top")) + parseInt(this.sidebar.getStyle("padding-bottom"));
    var messages_height = 0; // this.messages.visible() ? this.messages.getHeight() : 0;

    return body_height - top_of_content - sidebar_padding - messages_height + 3;
  },
  
  sidebarControlHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_content = this.content.offsetTop;
    var messages_height = 0; // this.messages.visible() ? this.messages.getHeight() : 0;

    return body_height - top_of_content - messages_height + 3;
  }
});

Content.setup = function() {
  Content.instance = new Content();
}
