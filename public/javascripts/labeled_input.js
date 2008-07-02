// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
document.observe('dom:loaded', function() {
  $$("input.example[type=text]").each(function(element) {
    var example_value = element.value;
    element.observe("focus", function() {
      if(element.value == example_value) {
        element.value = "";
        element.removeClassName("example");
      }
    });
    element.observe("blur", function() {
      if(element.value == "") {
        element.value = example_value;
        element.addClassName("example");
      }
    });
  });
});
