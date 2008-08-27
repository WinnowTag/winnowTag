Element.addMethods({
  insertInOrder: function(container, sibling_selector, sibling_value_selector, element_html, element_value) {
    var needToInsert = true;

    container.select(sibling_selector).each(function(element) {
      if(needToInsert) {
        var value_element = element.down(sibling_value_selector);
        if(value_element && value_element.innerHTML.unescapeHTML().toLowerCase() > element_value.toLowerCase()) {
          element.insert({before: element_html})
          needToInsert = false;
        }
      }
    });
 
    if(needToInsert) {
      container.insert({bottom: element_html});
    }
  }
});
