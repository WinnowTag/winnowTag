// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var BiasSlider = Class.create(Control.Slider, {
  initialize: function($super, handle, track, options) {
    $super(handle, track, options);
    this.initializeTicks();
  },
  setDisabled: function() {
    this.disabled = true;
    this.track.addClassName('disabled');    
  },
  setEnabled: function() {
    this.disabled = false;
    this.track.removeClassName('disabled');
  },
  sendUpdate: function(bias, tag_id) {
    new Ajax.Request("/tags/" + tag_id + "?tag[bias]=" + bias, {method: "PUT"});
  },
  initializeTicks: function() {
    var ticks = $H({0.9: "0_9", 1.0: "1_0", 1.1: "1_1", 1.2: "1_2", 1.3: "1_3"});
    ticks.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
      this.track.down("." + value).setStyle({left: this.translateToPx(key)});
      if(!this.disabled) {
        this.track.down("." + value).observe('mousedown', this.setValue.bind(this, key, 0));
      }
    }.bind(this));
  }
});

BiasSlider.sliders = {};