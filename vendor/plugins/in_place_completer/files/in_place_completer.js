Object.alias = function(pro, to, from) {
    pro[to] = pro[from];
    return pro;
}

Ajax.InPlaceEditor.LocalCompletion = Class.create();
Object.extend(Ajax.InPlaceEditor.LocalCompletion.prototype, Ajax.InPlaceEditor.prototype);
Object.alias(Ajax.InPlaceEditor.LocalCompletion.prototype, 'super_initialize', 'initialize');
Object.alias(Ajax.InPlaceEditor.LocalCompletion.prototype, 'super_createEditField', 'createEditField');
Object.alias(Ajax.InPlaceEditor.LocalCompletion.prototype, 'super_leaveEditMode', 'leaveEditMode');

Object.extend(Ajax.InPlaceEditor.LocalCompletion.prototype, {
    initialize: function(element, completion_element, completion_array, url, options, completion_options) {
            this.super_initialize(element,url,options);
            this.completion_element = completion_element;
            this.completion_array = completion_array;
            this.completion_options = completion_options;
        },
     createEditField: function() {
            var ret = this.super_createEditField();
            this.completer = new Autocompleter.Local(this.editField, this.completion_element, this.completion_array, this.completion_options);
            return ret;
        },
     leaveEditMode: function() {
            this.completer = null;
            this.super_leaveEditMode();
        }
    });

Ajax.InPlaceEditor.Completion = Class.create();
Object.extend(Ajax.InPlaceEditor.Completion.prototype, Ajax.InPlaceEditor.prototype);
Object.alias(Ajax.InPlaceEditor.Completion.prototype, 'super_initialize', 'initialize');
Object.alias(Ajax.InPlaceEditor.Completion.prototype, 'super_createEditField', 'createEditField');
Object.alias(Ajax.InPlaceEditor.Completion.prototype, 'super_leaveEditMode', 'leaveEditMode');

Object.extend(Ajax.InPlaceEditor.Completion.prototype, {
    initialize: function(element, completion_element, completion_url, url, options, completion_options) {
            this.super_initialize(element,url,options);
            this.completion_element = completion_element;
            this.completion_url = completion_url;
            this.completion_options = completion_options;
        },
     createEditField: function() {
            var ret = this.super_createEditField();
            this.completer = new Ajax.Autocompleter(this.editField, this.completion_element, this.completion_url, this.completion_options);
            return ret;
        },
     leaveEditMode: function() {
            this.completer = null;
            this.super_leaveEditMode();
        }
    });
