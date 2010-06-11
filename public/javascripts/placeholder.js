// TODO: determine whether we need this and behavior in labeled_input.js

// Hides or shows an element's placeholder text on focus or blur, respectively.
document.observe('dom:loaded', function() {
  $$("input[placeholder]").each(function(element) {
    element.realValue = function() {
      return element.blank() ? "" : element.value;
    };
    element.blank = function() {
      return element.value.blank() || element.value == element.getAttribute("placeholder");
    };
    element.showPlaceholder = function() {
      element.value = element.getAttribute("placeholder");
      element.addClassName("placeholder");
    };
    element.hidePlaceholder = function() {
      element.value = "";
      element.removeClassName("placeholder");
    };
    element.observe("focus", function() {
      if(element.value == element.getAttribute("placeholder")) { element.hidePlaceholder(); }
    });
    element.observe("blur", function() {
      if(element.value == "") { element.showPlaceholder(); }
    });
    
    // if(element.value == "") { element.showPlaceholder(); }
  });
});


