// Copyright (c) 2007 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please contact info@peerworks.org for further information.

var BiasSlider = Class.create();
BiasSlider.prototype = Object.extend(Control.Slider.prototype, {
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
  }
});