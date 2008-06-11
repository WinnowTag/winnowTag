document.observe('dom:loaded', function() {
  if($('sidebar')) {
    new Sidebar();
  }
});

var Sidebar = Class.create({
  initialize: function() {
    this.sidebar = $('sidebar');
    this.sidebar_control = $('sidebar_control');
    this.toggleListener = this.toggle.bind(this);
    
    if(Cookie.get("sidebar_width")) {
      this.sidebar.style.width = Cookie.get("sidebar_width") + 'px';
    }
    
    if(Cookie.get("show_sidebar")) {
      this.sidebar_control.addClassName("open")
      this.enableResize();
    } else {
      this.sidebar.hide();
    }
    
    this.enableToggle();
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

    resizeContentWidth();
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
    var sidebar_padding = parseInt(this.sidebar.getStyle("padding-left")) + parseInt(this.sidebar.getStyle("padding-right"));
    var sidebar_control_margin = parseInt(this.sidebar_control.getStyle("margin-left"));
    var sidebar_width = this.sidebar_control.cumulativeOffset().first() - sidebar_padding - sidebar_control_margin - 1;
    this.sidebar.style.width = sidebar_width + 'px';

    Cookie.set("sidebar_width", sidebar_width, 365);
    resizeContentWidth();
  }
});