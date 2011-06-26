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


// Enhance Prototype's Element class with some of our own methods
Element.addMethods({
  
  // Insert an element into the container in alphabetical order by its content or attribute.
  insertInOrder: function(container, sibling_value_selector, element_html, element_value) {
    
    // Strip the attribute name (if present) from the selector and store it separately
    var sibling_value_selector_parts = sibling_value_selector.split("@");
    sibling_value_selector = sibling_value_selector_parts[0];
    var sibling_value_selector_attribute = sibling_value_selector_parts[1];

    var needToInsert = true;

    container.childElements().each(function(element) {
      if(needToInsert) {
        var sibling_value_element = element.down(sibling_value_selector);
        
        var sibling_value;
        if(sibling_value_selector_attribute) {
          sibling_value = sibling_value_element && sibling_value_element.getAttribute(sibling_value_selector_attribute);
        } else {
          sibling_value = sibling_value_element && sibling_value_element.innerHTML.unescapeHTML();
        }
        
        if(sibling_value.toLowerCase() > element_value.toLowerCase()) {
          element.insert({ before: element_html });
          needToInsert = false;
        }
      }
    });
 
    if(needToInsert) {
      container.insert({ bottom: element_html });
    }
  },
  
  // Loads the givn element with content fetched via Ajax from its
  // 'url' attribute. When the Ajax request comopletes, invokes the
  // given onComplete callback.
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

// Converts the given string content into content in the DOM and returns it.
Element.fromHTML = function(html) {
  return new Element('div').update(html).down();
};
