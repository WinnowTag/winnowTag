// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Sidebar = Class.create({
  initialize: function(url, parameters, onLoad) {
    this.sidebar = $('sidebar');
    this.sidebar_control = $('sidebar_control');
    this.toggleListener = this.toggle.bind(this);
    
    if(Cookie.get("sidebar_width")) {
      this.sidebar.style.width = Cookie.get("sidebar_width") + 'px';
    }
    
    if(Cookie.get("show_sidebar") != false) {
      this.sidebar_control.addClassName("open")
      this.enableResize();
    } else {
      this.sidebar.hide();
    }
    
    this.enableToggle();
    this.load(url, parameters, onLoad);
  },
  
  enableToggle: function() {
    (function() { 
      this.sidebar_control.observe("click", this.toggleListener);
    }.bind(this)).delay(0.1);
  },
  
  disableToggle: function() {
    this.sidebar_control.stopObserving("click", this.toggleListener);
  },
  
  toggle: function() {
    this.sidebar.toggle();
    this.sidebar_control.toggleClassName("open")
    Cookie.set("show_sidebar", this.sidebar.visible(), 365);

    if(this.sidebar.visible()) {
      this.enableResize();
    } else {
      this.disableResize();
    }

    Content.instance.resizeWidth();
  },
  
  enableResize: function() {
    this.sidebar_control._draggable = new Draggable(this.sidebar_control, {constraint: 'horizontal', 
      change: this.resize.bind(this), 
      onStart: function() {
        this.sidebar_control.setStyle({backgroundColor: "#e1e1e1"});
        this.disableToggle();
      }.bind(this), 
      onEnd: function() {
        this.sidebar_control.setStyle({backgroundColor: ""});
        this.resize();
        this.enableToggle();
      }.bind(this)});
  },
  
  disableResize: function() {
    this.sidebar_control._draggable.destroy();
  },
  
  resize: function() {
    var sidebar_width = this.sidebar_control.cumulativeOffset().first() - 1;
    this.sidebar.style.width = sidebar_width + 'px';
    this.sidebar_control.style.left = 0;

    Cookie.set("sidebar_width", sidebar_width, 365);
    Content.instance.resizeWidth();
  },
  
  load: function(url, parameters, onComplete) {
    this.sidebar.addClassName("loading");

    new Ajax.Updater(this.sidebar, url, { method: 'get', evalScripts: true, parameters: parameters,
      onComplete: function() {
        this.sidebar.removeClassName("loading");
        onComplete();
      }.bind(this)
    });
  }
});