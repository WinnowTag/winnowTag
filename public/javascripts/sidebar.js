// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Manages the size and visible state of the sidebard on the items page.
var Sidebar = Class.create({
  initialize: function() {
    // Only one sidebar is open. We need to find it from feedItemsBrowser so
    // that the training panel can be opened and the cookie set properly,
    // if necessary when arriving from another page.
    Sidebar.instance = this;

    this.sidebar = $('sidebar');
    this.sidebar_normal = $('sidebar_normal');
    
    if (Cookie.get("training_mode") == "on") {
      this.togglePanel();
    } this.scrollSelectedTagIntoView.defer();
    
    $("sidebar_edit_toggle").observe("click", this.toggleEdit.bind(this));
  },

  // Depends upon cookie state being correctly sync'd with open/closed state of
  // training panel.
  ensurePanelOpen: function() {

    if (Cookie.get("training_mode") != "on") {
      this.togglePanel();
      Cookie.set("training_mode", "on", 365);
    }
  },
  
  toggleEdit: function() {
    this.clearFields();
    this.togglePanel(function() {
      this.toggleOpenItemTraining();
      this.toggleCookies();
    }.bind(this));
  },

  scrollSelectedTagIntoView: function() {
    if (typeof itemBrowser != 'undefined')
      itemBrowser.scrollSelectedTagIntoView();
  },

  togglePanel: function(afterFinish) {
    Effect.toggle("sidebar_edit", "slide", {
      afterUpdate: function(effect) {
        var height = $(effect.element).getHeight();
        this.sidebar_normal.style.top = (25 + height) + "px";
      }.bind(this),
      afterFinish: function(e) {
        this.toggleControl();
        
        if (!this.isEditing()) {
          this.sidebar_normal.style.top = "25px";
          $(document.body).removeClassName("create_tags_open")
        } else {
          $(document.body).addClassName("create_tags_open")
        }
        
        if (afterFinish) {
          afterFinish();
        }

        this.scrollSelectedTagIntoView();
      }.bind(this),
      duration: 0.3,
      queue: {
        position: 'end',
        scope: 'sidebarToggle',
        limit: 1
      }
    });
  },
  
  toggleCookies: function() {
    Cookie.set("training_mode", this.isEditing() ? "on" : "off", 365);
  },
  
  toggleControl: function() {
    $$("#sidebar_edit_toggle").each(function(e) {
      if (this.isEditing()) {
        e.title = I18n.t('winnow.items.sidebar.training_controls_toggle_open_tooltip');
        e.addClassName("open");
        e.removeClassName("closed");
      } else {
        e.title = I18n.t('winnow.items.sidebar.training_controls_toggle_closed_tooltip');
        e.addClassName("closed");
        e.removeClassName("open");
      }
    }.bind(this));
  },
  
  clearFields: function() {
    var clearedFilters = {};
    var needToClear = false;
    
    if (itemBrowser.filters.mode != "all") {
      clearedFilters.mode = "all";
      needToClear = true;
    }
    
    if (itemBrowser.filters.text_filter) {
      clearedFilters.text_filter = "";
      needToClear = true;
    }
    
    if (needToClear) {
      itemBrowser.addFilters({mode: "all", text_filter: ""});      
    }
    
    $("text_filter").clear();
    $("text_filter").showPlaceholder();
  },
  
  isEditing: function() {
    return $("sidebar_edit").visible();
  },
  
  toggleOpenItemTraining: function() {
    var selectedItem = itemBrowser.selectedItem();
    if (selectedItem && selectedItem._item.isOpen()) {
      if (this.isEditing()) {
        selectedItem._item.showTrainingControls();
      } else {
        selectedItem._item.hideTrainingControls();
      }
    }
  }
});
