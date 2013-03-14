/**
 * chainedForm - handles the form based on the json configured at the backend
 **/
var ChainedForm = {
  init : function(form, configURL) {
    var self = this;
    this.form = form;
    this.loading = this.form.find('._cf_loading');
    this.error = this.form.find('._cf_error');
    this.holder = this.form.find('._cf_holder');
    this.button = this.form.find('button').on('click', function(e) {
      e.preventDefault();
      $.each(self.services, function(key, service) {
        if (service.selected) {
          service.run();
        }
      });
    });
    this.configURL = configURL;
    this.services = {};
    this.loadServices();
  },

  loadServices: function() {
    this.error.empty().hide();
    this.loading.html('Loading services&#133;').show();
    $.ajax(this.configURL, {
      context: this,
      complete: function() {
        this.loading.hide();
      },
      success: function(json) {
        if (json.success) {
          for (var i in json.services) {
            this.services[json.services[i].service] = new RestService(json.services[i], this);
          }
          this.populateFormFields();
        } else {
          this.errorOut(json.error, 'loadServices');
        }
      },
      error: function() {
        this.errorOut('', 'loadServices');
      },
      dataType: 'json',
      cache: false
    });
  },

  populateFormFields: function() {
    var self = this;
    var select = $('<select>')
      .append('<option value="" disabled="disabled">Choose a service&#133;</option>')
      .appendTo(this.holder)
      .on('change', function() {
        var selectedVal = $(this).val();
        $.each(self.services, function(key, service) {
          service.selected = selectedVal == key;
          service.showHideArgs();
        });
      })
    ;
    this.servicesArgs = $('<div>').appendTo(this.holder);
    $.each(this.services, function(key, service) {
      service.init(select);
    });
  },

  errorOut: function(message, retryMethod) {
    message = message ? ': ' + message : '';
    this.error.append('AJAX Error' + message + ' (', $('<a href="#">Try again</a>').on('click', function(e) {
      e.preventDefault();
      ChainedForm[retryMethod]();
    }), ')').show();
  }
};

function RestService(data, parent) {
  $.extend(this, data);
  this.parent = parent;
  this.selected = false;

  this.init = function(select) {
    var self = this;
    this.option = select.append('<option value="' + this.service + '">' + this.service + '</option>');
    this.argsDiv = $('<div>').appendTo(this.parent.servicesArgs).hide();
    this.urlArgs = $.map(this.url.match(/\:[a-z]+/ig) || [], function(str) { return str.substr(1) });
    $.each($.merge($.merge([], this.urlArgs), this.arguments), function() {
      self.argsDiv.append('<label>' + this + '<input type="text" name="' + this + '"/></label>');
    });
  }

  this.showHideArgs = function() {
    this.argsDiv.toggle(this.selected);
  }
  
  this.run = function() {
    var self = this;
    var url = this.url;
    var values = {};
    $('input:visible').each(function() {
      if ($.inArray(this.name, self.urlArgs) > -1) {
        url = url.replace(':' + this.name, this.value);
      } else if (this.value) {
        values[this.name] = this.value;
      }
    });
    
    values['content-type'] = 'application/json';

    this.parent.loading.show().html('Fetching data&#133;');
    $.ajax(url, {
      context: this,
      complete: function() {
        this.parent.loading.hide();
      },
      success: function(json) {
        var select = $('<select>').appendTo(this.argsDiv);
        this.output = json;
        for (var i in json) {
          select.append('<option value="' + i  +'">' + JSON.stringify(json[i]) + '</option>');
        }
      },
      error: function() {//TODO
      },
      dataType: 'json',
      cache: false,
      data: values
    });
  }
}
