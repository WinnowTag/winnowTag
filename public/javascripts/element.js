// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
Element.addMethods({
  insertInOrder: function(container, sibling_selector, sibling_value_selector, element_html, element_value) {
    var sibling_value_selector_parts = sibling_value_selector.split("@");
    sibling_value_selector = sibling_value_selector_parts[0];
    var sibling_value_selector_attribute = sibling_value_selector_parts[1];

    var needToInsert = true;

    container.select(sibling_selector).each(function(element) {
      if(needToInsert) {
        var sibling_value_element = element.down(sibling_value_selector);
        
        var sibling_value;
        if(sibling_value_selector_attribute) {
          sibling_value = sibling_value_element && sibling_value_element.getAttribute(sibling_value_selector_attribute);
        } else {
          sibling_value = sibling_value_element && sibling_value_element.innerHTML.unescapeHTML();
        }
        if(sibling_value.toLowerCase() > element_value.toLowerCase()) {
          element.insert({before: element_html})
          needToInsert = false;
        }
      }
    });
 
    if(needToInsert) {
      container.insert({bottom: element_html});
    }
  },
  
  load: function(element, onComplete, forceLoad) {
    if(!forceLoad && !element.empty()) { return; }
    
    element.update("");
    element.addClassName("loading");
    new Ajax.Updater(element, element.getAttribute("url"), { method: 'get',
      onComplete: function() {
        element.removeClassName("loading");
        if(onComplete) { onComplete(); }
      }
    });
  }
});

Element.fromHTML = function(html) {
  return new Element('div').update(html).down();
};
