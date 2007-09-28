if (typeof DOMParser == "undefined" && typeof ActiveXObject != "undefined") {
  DOMParser = function() {}
  DOMParser.prototype.parseFromString = function (str, contentType) {
    var xml = new ActiveXObject("MSXML2.DomDocument.3.0");
	xml.preserveWhiteSpace = false;
    xml.loadXML(str);
    return xml;
  }
}

Object.extend(String.prototype, {
  trim: function() {
    //skip leading and trailing whitespace
    //and return everything in between
    return this.replace(/^\s*(.*)/, "$1").replace(/(.*?)\s*$/, "$1");
  }
});

//Object.extend(Element.Methods, {

  Element.Methods.remove = function(element) {
    element = $(element);
    if (element)
      element.parentNode.removeChild(element);
  }

  Element.Methods.replace = function(element, html) {
    var parser = new TaconiteParser($(element), html.stripScripts());
    parser.replace();
    setTimeout(function() {html.evalScripts()}, 10);
  }

  Element.Methods.update = function(element, html) {
    var parser = new TaconiteParser($(element), html.stripScripts());
    parser.update();
    setTimeout(function() {html.evalScripts()}, 10);
  }

//});
Object.extend(Element, Element.Methods);

Abstract.Insertion = function() {}

Abstract.Insertion.prototype = {
  initialize: function(element, content) {
    this.element = $(element);
    this.content = content.stripScripts();
    this.parser = new TaconiteParser(this.element, this.content);
    this.insertContent();

    setTimeout(function() {content.evalScripts()}, 10);
  }
}

var Insertion = new Object();

Insertion.Before = Class.create();
Insertion.Before.prototype = Object.extend(new Abstract.Insertion(), {
  insertContent: function() {
    this.parser.insertBefore();
  }
});

Insertion.Top = Class.create();
Insertion.Top.prototype = Object.extend(new Abstract.Insertion(), {
  insertContent: function() {
    this.parser.insertTop();
  }
});

Insertion.Bottom = Class.create();
Insertion.Bottom.prototype = Object.extend(new Abstract.Insertion(), {
  insertContent: function() {
    this.parser.insertBottom();
  }
});

Insertion.After = Class.create();
Insertion.After.prototype = Object.extend(new Abstract.Insertion(), {
  insertContent: function() {
    this.parser.insertAfter();
  }
});

Abstract.Relocation = function() {}

Abstract.Relocation.prototype = {
  initialize: function(element, content) {
    this.element = $(element);
    this.content = $(content);
    this.parser = new TaconiteParser(this.element, this.content);
    this.relocateContent();
  }
}

var Relocation = new Object();

Relocation.Before = Class.create();
Relocation.Before.prototype = Object.extend(new Abstract.Relocation(), {
  relocateContent: function() {
    this.parser.moveBefore();
  }
});

Relocation.Top = Class.create();
Relocation.Top.prototype = Object.extend(new Abstract.Relocation(), {
  relocateContent: function() {
    this.parser.moveTop();
  }
});

Relocation.Bottom = Class.create();
Relocation.Bottom.prototype = Object.extend(new Abstract.Relocation(), {
  relocateContent: function() {
    this.parser.moveBottom();
  }
});

Relocation.After = Class.create();
Relocation.After.prototype = Object.extend(new Abstract.Relocation(), {
  relocateContent: function() {
    this.parser.moveAfter();
  }
});

var TaconiteParser = Class.create();
TaconiteParser.prototype = {
  initialize: function(node, content) {
    this.isIE = document.uniqueID;
    this.contextNode = node;

    if (typeof content == "string")
    {
      var parser = new DOMParser;
      var doc = parser.parseFromString('<prototype>' + content + '</prototype>', 'text/xml');
      this.tempNode = doc.documentElement;
    }
    else
    {
      this.referenceNode = content;
      this.tempNode = content.cloneNode(true);
    }
  },

  insertTop: function() {
    var firstNode = null;
    var childNode = null;

    if (this.contextNode.childNodes.length > 0) {
      firstNode = this.contextNode.childNodes[0];

      for (var i = 0; i < this.tempNode.childNodes.length; i++) {
        childNode = this.handleNode(this.tempNode.childNodes[i]);
        if (childNode != null) {
          if (firstNode == null) {
            this.contextNode.appendChild(childNode);
            firstNode = childNode;
          } else {
            this.contextNode.insertBefore(childNode, firstNode);
          }
        }
      }
    }
  },

  moveTop: function() {
    var firstNode = null;

    if (this.contextNode.childNodes.length > 0) {
      firstNode = this.contextNode.childNodes[0];

      if (firstNode == null) {
        this.contextNode.appendChild(this.tempNode);
      } else {
        this.contextNode.insertBefore(this.tempNode, firstNode);
      }
    }

    this.referenceNode.parentNode.removeChild(this.referenceNode);
  },

  insertBottom: function() {
    var childNode = null;
    for (var i = 0; i < this.tempNode.childNodes.length; i++) {
      childNode = this.handleNode(this.tempNode.childNodes[i]);
      if (childNode != null)
        this.contextNode.appendChild(childNode);
    }
  },

  moveBottom: function() {
	this.contextNode.appendChild(this.tempNode);
    this.referenceNode.parentNode.removeChild(this.referenceNode);
  },

  insertAfter: function() {
    var childNode = null;
    var nextSibling = this.contextNode.nextSibling;
    for (var i = 0; i < this.tempNode.childNodes.length; i++) {
      childNode = this.handleNode(this.tempNode.childNodes[i]);
      if (nextSibling != null)
        this.contextNode.parentNode.insertBefore(childNode, nextSibling);
      else
        this.contextNode.parentNode.appendChild(childNode);
    }
  },

  moveAfter: function() {
    var nextSibling = this.contextNode.nextSibling;

    if (nextSibling != null)
      this.contextNode.parentNode.insertBefore(this.tempNode, nextSibling);
    else
      this.contextNode.parentNode.appendChild(this.tempNode);

    this.referenceNode.parentNode.removeChild(this.referenceNode);
  },

  insertBefore: function() {
    var childNode = null;
    for (var i = 0; i < this.tempNode.childNodes.length; i++) {
      childNode = this.handleNode(this.tempNode.childNodes[i]);
      if (childNode != null)
        this.contextNode.parentNode.insertBefore(childNode, this.contextNode);
    }
  },

  moveBefore: function() {
    this.contextNode.parentNode.insertBefore(this.tempNode, this.contextNode);
    this.referenceNode.parentNode.removeChild(this.referenceNode);
  },

  replace: function() {
    this.insertAfter();
    this.contextNode.parentNode.removeChild(this.contextNode);
  },

  update: function() {
    while (this.contextNode.childNodes.length > 0)
      this.contextNode.removeChild(this.contextNode.childNodes[0]);

    this.insertBottom();
  },

  isInlineMode: function(node) {
    var attrType;
    if(!node.tagName.toLowerCase() == "input") {
      return false;
    }
    attrType=node.getAttribute("type");

    if(attrType=="radio" || attrType=="checkbox") {
      return true;
    }
    return false;
  },

  handleNode: function(xmlNode) {
    var nodeType = xmlNode.nodeType;
    switch(nodeType) {
      case 1:  //ELEMENT_NODE
        return this.handleElement(xmlNode);
      case 3:  //TEXT_NODE
      case 4:  //CDATA_SECTION_NODE
        return document.createTextNode(xmlNode.nodeValue);
    }
    return null;
  },

  handleElement: function(xmlNode) {
    var domElemNode=null;
    var xmlNodeTagName=xmlNode.tagName.toLowerCase();
    if (this.isIE) {
      if (this.isInlineMode(xmlNode)) {
        return document.createElement("<INPUT " + this.handleAttributes(domElemNode,xmlNode,true) + ">");
      }
      if (xmlNodeTagName == "style") {
        //In internet explorer, we have to use styleSheets array.
        var text,rulesArray,styleSheetPtr;
        var regExp = /\s+/g;
        text=xmlNode.text.replace(regExp, " ");
        rulesArray=text.split("}");

        domElemNode=document.createElement("style");
        styleSheetPtr=document.styleSheets[document.styleSheets.length-1];
        for (var i=0;i<rulesArray.length;i++) {
          rulesArray[i]=rulesArray[i].trim();
          var rulePart=rulesArray[i].split("{");
          if (rulePart.length==2) { //Add only if the rule is valid
            styleSheetPtr.addRule(rulePart[0],rulePart[1],-1);//Append at the end of stylesheet.
          }
        }
        return domElemNode;
      }

    }
    if (domElemNode == null) {
      domElemNode=document.createElement(xmlNodeTagName);
      this.handleAttributes(domElemNode,xmlNode);
      //Fix for IE Script tag: Unexpected call to method or property access error
      //IE don't allow script tag to have child
      if (this.isIE && !domElemNode.canHaveChildren) {
        if(xmlNode.childNodes.length > 0){
          domElemNode.text=xmlNode.text;
        }

      } else {
        for(var z = 0; z < xmlNode.childNodes.length; z++) {
          var domChildNode=this.handleNode(xmlNode.childNodes[z]);
          if(domChildNode!=null) {
            domElemNode.appendChild(domChildNode);
          }
        }
      }
    }

    return domElemNode;
  },

  handleAttributes: function(domNode,xmlNode) {
    var attr = null;
    var attrString = "";
    var name = "";
    var value = "";
    var returnAsText=false;
    if(arguments.length==3) {
      returnAsText = true;
    }

    for (var x = 0; x < xmlNode.attributes.length; x++) {
      attr = xmlNode.attributes[x];
      name = attr.name.trim();
      value = attr.value.trim();
      if (!returnAsText) {
        if(name == "style") {
          /* IE workaround */
          domNode.style.cssText=value;
          /* Standards compliant */
          domNode.setAttribute(name,value);
        }
        else if(name.trim().toLowerCase().substring(0, 2) == "on") {
          /* IE workaround for event handlers */
          //domNode.setAttribute(name,value);
          eval("domNode." + name.trim().toLowerCase() + "=function(){" + value + "}");
        }
        else {
          /* Standards compliant */
          domNode.setAttribute(name,value,0);
                                       
        }
        /* class attribute workaround for IE */
        if(name == "class") {
          domNode.setAttribute("className",value);
        }
      }else{
        attrString = attrString + name + "=\"" + value + "\" " ;
      }
    }
    return attrString;
  }
}
