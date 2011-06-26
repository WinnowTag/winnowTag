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


// Initializes the bias slider and sends updates to it as Ajax requests
// to the address stored in the 'href' attribute of the slider. The bias
// slider appears in the tag panel that is shown when the user clicks on
// a tag "row" on the My Tags or Public Tags page.
var BiasSlider = Class.create(Control.Slider, {
  initialize: function($super, slider) {
    this.slider = slider;
    
    var handle = this.slider.down(".slider_handle");
    var track = this.slider.down(".slider_track");
    var bias = parseFloat(this.slider.getAttribute("bias"));
    var options = {
      disabled: this.slider.match("[disabled]"),
			sliderValue: bias,
			range: $R(0.9, [bias, 1.3].max()), 
			onChange: this.sendUpdate.bind(this)
		};
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
  
  sendUpdate: function(bias) {
    new Ajax.Request(this.slider.getAttribute("href"), {
      method: this.slider.getAttribute("method"),
      parameters: { "tag[bias]": bias }
    });
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