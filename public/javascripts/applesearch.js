var applesearch;
if (!applesearch)	applesearch = {};

applesearch.init = function () {
	if (navigator.userAgent.toLowerCase().indexOf('safari') < 0) {
		$$(".applesearch").each(function(element) {
		  element.addClassName("non_safari");
		  
		  var text_input = element.down("input");
		  var clear_button = element.down('.srch_clear');
		  Event.observe(text_input, 'keyup', function() {
		    applesearch.onChange(text_input, clear_button);
	    });
		  Event.observe(text_input, 'focus', function() {
		    applesearch.removePlaceholder(text_input);
	    });
		  Event.observe(text_input, 'blur', function() {
		    applesearch.onChange(text_input, clear_button);
		    applesearch.insertPlaceholder(text_input);
	    });
		  Event.observe(clear_button, 'click', function() {
		    applesearch.clearFld(text_input, clear_button);
	    });
	    
      applesearch.onChange(text_input, clear_button);
      applesearch.insertPlaceholder(text_input);
		});
	}
}

applesearch.onChange = function (fld, btn) {
	if (fld.value.length > 0 && !btn.hasClassName("clear_button")) {
	  btn.addClassName("clear_button");
	} else if (fld.value.length == 0 && btn.hasClassName("clear_button")) {
	  btn.removeClassName("clear_button");
	}
}

applesearch.clearFld = function (fld,btn) {
	fld.value = "";
	this.onChange(fld,btn);
	fld.focus();
}

applesearch.insertPlaceholder = function(fld) {
  if(fld.value == "") {
	  fld.addClassName("placeholder");
	  fld.value = fld.getAttribute("placeholder");
  }
}

applesearch.removePlaceholder = function(fld) {
   if(fld.value == fld.getAttribute("placeholder")) {
	  fld.removeClassName("placeholder");
	  fld.value = "";
  }
}