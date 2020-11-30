function LogBingMapServiceDown() {
  $.ajax({
    url: '/Home/BingMapServiceDown',
    success: function (msg) {
    }
  });
  return false;
}

function openAlertMessage(alertMessage, fnCloseCallback) {
  /// <summary>
  /// Custom Alert modal window
  /// </summary>
  /// <param name="alertMessage">Message</param>
  /// <param name="fnCloseCallback">Callback that should be invoked while closing the window.</param>

  $.modal.alert(alertMessage, {
    buttons: {
      'OK': {
        classes: 'huge blue-gradient glossy full-width',
        click: function (win) { win.closeModal(); }
      }
    },
    onClose: function () { if (fnCloseCallback != null) { fnCloseCallback(); } return true; }
  });
}

// Put the first editable input control in to focus.
$(function () {
  setTimeout(function () {
    /// <summary>
    /// 
    /// </summary>
    var firstField = $("form").find("input[type=text]").not(":disabled").not("[readonly]").first(); //$("input[type=text]").first();
    firstField.focus();
  }, 1000);

});

var queueDetailWindow;

function ShowServiceRequestDetails(actionURL, id, popupTitle, isEditRequired) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="actionURL"></param>
  /// <param name="id"></param>
  /// <param name="popupTitle"></param>
  /// <param name="isEditRequired"></param>
  mode = "edit";
  title = "Service Request ID: " + id;
  $.ajax({
    type: 'POST',
    url: actionURL,
    traditional: true,
    data: { queueId: id, fromStartCall: true, isEditRequired: isEditRequired },
    cache: false,
    async: false,
    success: function (msg) {
      queueDetailWindow = $("<div id='queueDetailWindow' />").appendTo(document.body);
      queueDetailWindow.kendoWindow({
        title: title,
        modal: true,
        width: 1200,
        height: GetPopupWindowHeight(),
        deactivate: function () {
          this.destroy();
        },
        close: function () {
          if (document.dialogResult == null || document.dialogResult == "CANCEL") {
            document.dialogResult = null;
            if (!IsPageDirty()) {
              return false;
            }
          }
          isdirty = false;
          $(this).remove();
          return true;
        }
      });
      queueDetailWindow.data('kendoWindow').content(msg).center().open();
    } // end of success callback
  }); // end of ajax
}


/* FOR ADDRESSES */

function AddressesGrid(grid) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="grid"></param>
  this._grid = grid;

  this.getInsertedAddresses = function () {

    var insertedAddresses = $.grep(this._grid.dataSource.data(), function (model) {
      return model.isNew();
    });

    for (var i = 0, l = insertedAddresses.length; i < l; i++) {
      insertedAddresses[i].AddressTypeReference = insertedAddresses[i].EntityReference = insertedAddresses[i].CountryReference = insertedAddresses[i].StateProvince1Reference = null;
    }

    return insertedAddresses;
  }

  this.getUpdatedAddresses = function () {
    var updatedAddresses = $.grep(this._grid.dataSource.data(), function (model) {
      return (model.dirty && model.ID != 0);
    });
    for (var i = 0, l = updatedAddresses.length; i < l; i++) {

      updatedAddresses[i].AddressTypeReference = updatedAddresses[i].EntityReference = updatedAddresses[i].CountryReference = updatedAddresses[i].StateProvince1Reference = null;
      // Set the AddressTypeID, CountryID and StateProvinceID
      if (updatedAddresses[i].AddressType != null) {
        updatedAddresses[i].AddressTypeID = updatedAddresses[i].AddressType.ID;
      }
      if (updatedAddresses[i].Country != null) {
        updatedAddresses[i].CountryID = updatedAddresses[i].Country.ID;
      }
      if (updatedAddresses[i].StateProvince1 != null) {
        updatedAddresses[i].StateProvinceID = updatedAddresses[i].StateProvince1.ID;
      }
    }
    return updatedAddresses;

  }

  this.getDeletedAddresses = function () {

    var deletedAddresses = this._grid.dataSource._destroyed;
    for (var i = 0, l = deletedAddresses.length; i < l; i++) {

      deletedAddresses[i].AddressTypeReference = deletedAddresses[i].EntityReference = deletedAddresses[i].CountryReference = deletedAddresses[i].StateProvince1Reference = null;
    }
    return deletedAddresses;
  }
}

function PhoneGrid(grid) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="grid"></param>
  this._grid = grid;

  this.getInsertedPhoneDetails = function () {
    var insertedPhoneDetails = this._grid.insertedDataItems();
    for (var i = 0, l = insertedPhoneDetails.length; i < l; i++) {
      insertedPhoneDetails[i].PhoneTypeReference = insertedPhoneDetails[i].EntityReference = null;
    }
    return insertedPhoneDetails;
  }

  this.getUpdatedPhoneDetails = function () {
    var updatedPhoneDetails = this._grid.updatedDataItems();
    for (var i = 0, l = updatedPhoneDetails.length; i < l; i++) {

      updatedPhoneDetails[i].PhoneTypeReference = updatedPhoneDetails[i].EntityReference = null;
      // Set the PhoneTypeID
      if (updatedPhoneDetails[i].PhoneType != null) {
        updatedPhoneDetails[i].PhoneTypeID = updatedPhoneDetails[i].PhoneType.ID;
      }

    }
    return updatedPhoneDetails;

  }

  this.getDeletedPhoneDetails = function () {

    var deletedPhoneDetails = this._grid.deletedDataItems();
    for (var i = 0, l = deletedPhoneDetails.length; i < l; i++) {

      deletedPhoneDetails[i].PhoneTypeReference = deletedPhoneDetails[i].EntityReference = null;
    }
    return deletedPhoneDetails;
  }
}

// Phone number validation
var phoneUtil = null;
var PNF = null;
if (typeof (i18n) != 'undefined') {
  phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
  PNF = i18n.phonenumbers.PhoneNumberFormat;
}
function IsPhoneNumberValid(phoneNumber, regionCode) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="phoneNumber"></param>
  /// <param name="regionCode"></param>
  /// <returns type=""></returns>
  if ($.trim(phoneNumber).length > 0) {
    try {
      var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
      return phoneUtil.isValidNumberForRegion(number, regionCode);
    }
    catch (error) {
      // possible error due to invalid phone number (w.r.t the number of digits).
    }
  }
  return true;
}

function GetRegionCodeForPhone(phoneNumber) {
  try {
    if (phoneNumber.length > 1) {
      var number = phoneUtil.parseAndKeepRawInput(phoneNumber, null);
      regionCode = phoneUtil.getRegionCodeForNumber(number);
      return regionCode;
    }

  } catch (e) {

  }

  return "";
}
function GetFormattedPhoneNumber(phoneNumber, regionCode) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="phoneNumber"></param>
  /// <param name="regionCode"></param>
  /// <returns type=""></returns>
  try {
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    return phoneUtil.format(number, PNF.INTERNATIONAL);
  }
  catch (error) {
    // possible error due to invalid phone number (w.r.t the number of digits).
    return '';
  }
}

function GetFormattedPhoneNumberWithoutCountryCode(phoneNumber, regionCode) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="phoneNumber"></param>
  /// <param name="regionCode"></param>
  /// <returns type=""></returns>
  try {
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var fullFormat = phoneUtil.format(number, PNF.INTERNATIONAL);
    var tokens = fullFormat.split(' ');
    // remove the first token and give the rest.
    // This change is due to the formatting of Mexico numbers.
    tokens.splice(0, 1);
    //return fullFormat.split(' ')[1];
    return tokens.join(' ');
  }
  catch (error) {
    // possible error due to invalid phone number (w.r.t the number of digits).
    return '';
  }
}

function SetPhoneValues(prefix, fullPhoneNumber, isReadOnly) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="prefix"></param>
  /// <param name="fullPhoneNumber"></param>
  /// <param name="isReadOnly"></param>
  var number = null;
  var regionCode = null;

  if (prefix.indexOf("#") == -1) {
    prefix = "#" + prefix;
  }
  if (fullPhoneNumber != null && fullPhoneNumber.indexOf("+") == -1) {
    fullPhoneNumber = "+" + fullPhoneNumber;
  }
  if (fullPhoneNumber.length > 1) {
    number = phoneUtil.parseAndKeepRawInput(fullPhoneNumber, null);
    regionCode = phoneUtil.getRegionCodeForNumber(number);
  }

  if (isReadOnly) {
    if (number != null) {
      var formattedNumber = GetFormattedPhoneNumber(fullPhoneNumber, regionCode);
      $(prefix + '_lblPhoneNumber').html(formattedNumber);
    }
    else {
      $(prefix + '_lblPhoneNumber').html("");
    }
  }
  else {

    var countryCodeCombo = $(prefix + "_ddlCountryCode").data('kendoComboBox');
    if (number != null) {

      countryCodeCombo.select(function (dataItem) {
        return dataItem.Value === regionCode;
      });

      var telephoneNumber = GetFormattedPhoneNumberWithoutCountryCode(number.getNationalNumber().toString(), regionCode);
      var extension = number.getExtension();
      // Set these on the textfields
      $(prefix + '_txtPhoneNumber').val(telephoneNumber);
      $(prefix + '_txtExtension').val(extension);
    }
    else {
      countryCodeCombo.select(0);
      $(prefix + '_txtPhoneNumber').val("");
      $(prefix + '_txtExtension').val("");
    }
  }
}

function GetPhoneNumberFromFormat(fullPhoneNumberFromDB) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="fullPhoneNumberFromDB"></param>
  /// <returns type=""></returns>
  var fullPhoneNumber = "+" + fullPhoneNumberFromDB;
  var number = phoneUtil.parseAndKeepRawInput(fullPhoneNumber, null);
  return number;

}
function GetPhoneNumberForDB(phoneElementFor) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="phoneElementFor"></param>
  /// <returns type=""></returns>
  try {

    var $countryCode = $("#" + phoneElementFor + "_ddlCountryCode");
    if ($countryCode.length > 0) // We have text boxes
    {
      var $phoneNumber = $("#" + phoneElementFor + "_txtPhoneNumber");
      var $extension = $("#" + phoneElementFor + "_txtExtension");


      var regionCode = $countryCode.data("kendoComboBox").value();
      var phoneNumber = $phoneNumber.val() + "x" + $extension.val();
      var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
      if (number.getExtension() != null) {
        return number.getCountryCode() + " " + number.getNationalNumber() + "x" + number.getExtension();
      }
      else {
        return number.getCountryCode() + " " + number.getNationalNumber();
      }
    }
    else // Assuming that the control got rendered as readonly
    {

      var $label = $("#" + phoneElementFor + "_lblPhoneNumber");
      var formattedNumber = $label.html();
      var number = phoneUtil.parseAndKeepRawInput(formattedNumber, null);

      if (number.getExtension() != null) {
        return number.getCountryCode() + " " + number.getNationalNumber() + "x" + number.getExtension();
      }
      else {
        return number.getCountryCode() + " " + number.getNationalNumber();
      }
    }

    return '';
  }
  catch (error) {
    // possible error due to invalid phone number (w.r.t the number of digits).
    return '';
  }
}

function checkPhone(field, rules, i, options) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="field"></param>
  /// <param name="rules"></param>
  /// <param name="i"></param>
  /// <param name="options"></param>
  /// <returns type=""></returns>
  var $countryCodeInput = field.parents(".phone-input").find(".countryCode");
  var phoneNumber = field.val();
  var $countryCode = null;
  if ($countryCodeInput.length > 0) {
    $countryCodeInput.each(function () {
      if ($(this).attr("type") == "text") {
        $countryCode = $("#" + $(this).attr("name").replace("_input", ""));
      }
    });

  }

  var regionCode = $countryCode.data("kendoComboBox").value();

  if (!IsPhoneNumberValid(phoneNumber, regionCode)) {
    return "Invalid phone number";
  }
  else {
    var formattedNumber = GetFormattedPhoneNumberWithoutCountryCode(phoneNumber, regionCode);
    field.val(formattedNumber);
  }
}

// The following date functions assume that date.js is already referenced.
function CheckDate(field, rules, i, options) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="field"></param>
  /// <param name="rules"></param>
  /// <param name="i"></param>
  /// <param name="options"></param>
  /// <returns type=""></returns>
  if ($.trim(field.val()).length > 0) {
    var test = Date.parseExact(field.val(), "MM/dd/yyyy");
    if (!test) {
      return "Invalid date. Enter date in MM/DD/YYYY format";
    }
  }
}



function checkEmail(emailText) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="emailText"></param>
  /// <returns type=""></returns>
  var regex = { "expression": /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i };
  var test = emailText.match(regex.expression);
  if (!test) {
    return false;
  }
  return true;

}

function CheckFutureDate(field, rules, i, options) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="field"></param>
  /// <param name="rules"></param>
  /// <param name="i"></param>
  /// <param name="options"></param>
  /// <returns type=""></returns>
  var test = Date.parseExact(field.val(), "MM/dd/yyyy");
  if (!test) {
    return "Invalid date. Enter date in MM/DD/YYYY format";
  }

  // Extract the segments and compare the value against current date.
  if (test.compareTo(Date.today()) <= 0) {
    return "Please enter a future date";
  }
}

function CheckFutureDateNextSend(field, rules, i, options) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="field"></param>
  /// <param name="rules"></param>
  /// <param name="i"></param>
  /// <param name="options"></param>
  /// <returns type=""></returns>
  if ($.trim(field.val()).length == 0) {
    return;
  }
  var nextsend = Date.parseExact(field.val(), "MM/dd/yyyy");
  if (!nextsend) {
    return "Invalid date. Enter date in MM/DD/YYYY format";
  }

  // Extract the segments and compare the value against current date.
  if (nextsend.compareTo(Date.today()) < 0) {
    return "Please enter a future date";
  }
}

function ShowValidationMessage(element, message, position) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="element"></param>
  /// <param name="message"></param>
  var id = element.attr("id");
  if (id == null) {
    var name = element.attr("name");
    if (name != undefined) {
      name = name.replace(".", "_");
      element.attr("id", name + "-jqv");
    }
  }
  if (position == null) {
    element.validationEngine('showPrompt', message, '', 'topRight', true);
  }
  else {
    element.validationEngine('showPrompt', message, '', position, true);
  }
}
function HideValidationMessage(element) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="element"></param>
  var id = element.attr("id");
  if (id == null) {
    var name = element.attr("name");
    if (name != undefined) {
      name = name.replace(".", "_");
      element.attr("id", name + "-jqv");
    }
  }
  element.validationEngine('hidePrompt');
}

function CompareDates(d1, d2, format) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="d1"></param>
  /// <param name="d2"></param>
  /// <param name="format"></param>
  /// <returns type=""></returns>
  var date1 = Date.parseExact(d1, format);
  var date2 = Date.parseExact(d2, format);
  return date1.compareTo(date2);
}

function FormatPhoneNumber(table, colIndex) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="table"></param>
  /// <param name="colIndex"></param>
  table.find('tr').each(function () {
    var activeColumn = $("td:eq(" + colIndex + ")", this);
    if (activeColumn.length > 0) {
      var fullPhoneNumber = activeColumn.text();
      var tokens = fullPhoneNumber.split(' ');
      if (tokens.length == 1) { // Default to US region
        fullPhoneNumber = '+1 ' + fullPhoneNumber;
      }
      else {
        fullPhoneNumber = '+' + fullPhoneNumber;
      }

      activeColumn.html(GetFormattedPhoneNumber(fullPhoneNumber, null));
    }

  });
}

// This method is used to validate if the user typed an entry that is in the allowed set of values.
// If the user input is not in the allowed set of values, then the value and text properties of the dropdown are reset.
function IsUserInputValidForChange(combo) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="combo"></param>
  /// <returns type=""></returns>
  var isValidSelection = true;
  var inputLength = combo.value().length;
  if (combo.selectedIndex < 0) {
    combo.value('');
    combo.text('');
    combo.selectedValue = '';

    if (inputLength == 0) {
      return true;
    }
    combo.reload();
    return false;
  }

  if (combo.value() == "Select") {
    combo.value("");
  }
  // Cancel the event 
  if (combo.previousValue == combo.value()) {
    return false;
  }
  return isValidSelection;
}

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:::                                                                         :::
//:::  This routine calculates the distance between two points (given the     :::
//:::  latitude/longitude of those points).                                   :::
//:::  Definitions:                                                           :::
//:::    South latitudes are negative, east longitudes are positive           :::
//:::                                                                         :::
//:::  Passed to function:                                                    :::
//:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
//:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
//:::    unit = the unit you desire for results                               :::
//:::           where: 'M' is statute miles                                   :::
//:::                  'K' is kilometers (default)                            :::
//:::                  'N' is nautical miles                                  :::
//:::                                                                         :::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

function distance(lat1, lon1, lat2, lon2, unit) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="lat1"></param>
  /// <param name="lon1"></param>
  /// <param name="lat2"></param>
  /// <param name="lon2"></param>
  /// <param name="unit"></param>
  /// <returns type=""></returns>
  var radlat1 = Math.PI * lat1 / 180
  var radlat2 = Math.PI * lat2 / 180
  var radlon1 = Math.PI * lon1 / 180
  var radlon2 = Math.PI * lon2 / 180
  var theta = lon1 - lon2
  var radtheta = Math.PI * theta / 180
  var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
  dist = Math.acos(dist)
  dist = dist * 180 / Math.PI
  dist = dist * 60 * 1.1515
  if (unit == "K") { dist = dist * 1.609344 }
  if (unit == "N") { dist = dist * 0.8684 }
  return dist
}

// Create a jquery plugin that prints the given element.
jQuery.fn.print = function () {
  /// <summary>
  /// 
  /// </summary>

  // NOTE: We are trimming the jQuery collection down to the
  // first element in the collection.
  if (this.size() > 1) {
    this.eq(0).print();
    return;
  } else if (!this.size()) {
    return;
  }

  // ASSERT: At this point, we know that the current jQuery
  // collection (as defined by THIS), contains only one
  // printable element.

  // Create a random name for the print frame.
  var strFrameName = ("printer-" + (new Date()).getTime());

  // Create an iFrame with the new name.
  var jFrame = $("<iframe name='" + strFrameName + "'>");

  // Hide the frame (sort of) and attach to the body.
  jFrame
  .css("width", "1px")
  .css("height", "1px")
  .css("position", "absolute")
  .css("left", "-9999px")
  .appendTo($("body:first"))
  ;

  // Get a FRAMES reference to the new frame.
  var objFrame = window.frames[strFrameName];

  // Get a reference to the DOM in the new frame.
  var objDoc = objFrame.document;

  // Grab all the style tags and copy to the new
  // document so that we capture look and feel of
  // the current document.

  // Create a temp document DIV to hold the style tags.
  // This is the only way I could find to get the style
  // tags into IE.
  var jStyleDiv = $("<div>").append(
  $("style").clone()
  );

  // Write the HTML for the document. In this, we will
  // write out the HTML of the current element.
  objDoc.open();
  objDoc.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">");
  objDoc.write("<html>");
  objDoc.write("<body>");
  objDoc.write("<head>");
  objDoc.write("<title>");
  objDoc.write(document.title);
  objDoc.write("</title>");
  objDoc.write(jStyleDiv.html());
  objDoc.write("</head>");
  objDoc.write(this.html());
  objDoc.write("</body>");
  objDoc.write("</html>");
  objDoc.close();

  // Print the document.
  objFrame.focus();
  objFrame.print();

  // Have the frame remove itself in about a minute so that
  // we don't build up too many of these frames.
  setTimeout(
  function () {
    jFrame.remove();
  },
  (60 * 1000)
  );
}

function SearchOnEnter(formName, ButtonName) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="formName"></param>
  /// <param name="ButtonName"></param>
  $('#' + formName + ' input').keypress(function (e) {
    if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
      $('#' + ButtonName).click();
      return false;
    }
    else {
      return true;
    }
  });
}

// This method is used to validate if the user typed an entry that is in the allowed set of values.
// If the user input is not in the allowed set of values, then the value and text properties of the dropdown are reset.
function IsUserInputValidForChangeOnKendoCombo(combo) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="combo"></param>
  /// <returns type=""></returns>
  var isValidSelection = true;
  var inputLength = combo.text().length;
  if (combo.select() < 0) {
    if (inputLength == 0) {
      return true;
    }
    combo.value('');
    combo.text('');
    combo.search('');

    return false;
  }
  else if (combo.value() == '') {
    combo.select(function (dataItem) {
      dataItem.Text === combo.text();
    });
  }

  if (combo.value() == "Select") {
    combo.value("");
  }

  return isValidSelection;
}

function ValidateInputForKendoCombo(e) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="e"></param>
  /// <returns type=""></returns>
  var combo = e.sender;
  if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
    e.preventDefault();
    return false;
  }
  return true;
}

/* Kendo Grid error handler */
function KendoGridErrorHandler(e) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="e"></param>
  if (e.errors) {
    var message = "Errors:\n";
    $.each(e.errors, function (key, value) {
      if ('errors' in value) {
        $.each(value.errors, function () {
          message += this + "\n";
        });
      }
    });
    openAlertMessage(message);
  }
}

// Attach a double-click event handler for rows in kendo grid.
// $gridElement - jquery element (eg: $("#GrdUsers")
// buttonClass - the class associated with the action button (eg: ".k-grid-Edit") [Note: . is mandatory]
function HandleDblClickOnGrid($gridElement, buttonClass) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="$gridElement"></param>
  /// <param name="buttonClass"></param>
  $gridElement.delegate("tbody>tr", "dblclick", function () {
    $(this).find(buttonClass).click();
  });
}



function AdjustDropdownContainerWidth(combo, width) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="combo"></param>
  /// <param name="width"></param>
  if (combo != null) {
    if (typeof (width) != "undefined" && width != null) {
      combo.list.width(width);
    }
    else {
      combo.list.width(250);
    }
  }
}

function DefaultDataBoundToAdjustContainerWidth(e) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="e"></param>
  AdjustDropdownContainerWidth(e.sender, 250);
}

//SetFocusOnField
function SetFocusOnField(combo, form) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="combo"></param>

  var comboChild = $("#" + combo).data("kendoComboBox");
  var comboChildInputField = $('input[name= "' + combo + '_input"]');
  if (form != null) {
    comboChild = form.find("#" + combo).data("kendoComboBox");
    comboChildInputField = form.find('input[name= "' + combo + '_input"]');
  }
  if (comboChild != null && comboChild.focus) {
    comboChild.focus();
  }
  else {
    console.log("Combobox is not ready yet!");
  }
  comboChildInputField.focus();
  comboChildInputField.select();
}

/**
* Display a confirm prompt
* @param string message the message, as text or html
* @param function confirmCallback the function called when hitting confirm
* @param function cancelCallback the function called when hitting cancel or closing the modal
* @param object options same as $.modal() (optional)
* @return jQuery the new window
*/
$.modal.confirmFeedback = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Done': {
        classes: 'glossy',
        click: function (modal) { modal.closeModal(); }
      },

      'Send another': {
        classes: 'blue-gradient glossy',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}

$.modal.confirmYesNo = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Yes': {
        classes: 'blue-gradient glossy',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      },

      'No': {
        classes: 'glossy',
        click: function (modal) { modal.closeModal(); }

      }

    }

  }));
}

$.modal.confirmOKCancel = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'OK': {
        classes: 'blue-gradient glossy',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      },

      'Cancel': {
        classes: 'glossy',
        click: function (modal) { modal.closeModal(); }

      }

    }

  }));
}
/* Modal window after verify invoice operation is complete. */
$.modal.VerificationResults = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Close': {
        classes: 'glossy',
        click: function (modal) { modal.closeModal(); }
      },

      'Work Exceptions': {
        classes: 'red-gradient glossy workExceptions',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}

$.modal.SRLockedCommentsResults = function (message, confirmCallback, cancelCallback, addCommentCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'OK': {
        classes: 'glossy',
        click: function (modal) { // Callback
          modal.closeModal();
        }
      },

      'View': {
        classes: 'glossy blue-gradient',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          cancelCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      },
      'Add Comment': {
        classes: 'glossy green-gradient',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          addCommentCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}

/* Window that appears after verification is complete during Pay Invoices */
$.modal.VerificationResultsForPayment = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Post Invoices': {
        classes: 'green-gradient glossy payInvoices',
        click: function (modal) { modal.closeModal(); }
      },

      'Work Exceptions': {
        classes: 'red-gradient glossy workExceptions',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}

/* Window that appears after verification is complete during Pay Invoices */
$.modal.VerificationResultsForPaymentClaims = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Pay Claims': {
        classes: 'green-gradient glossy payClaims',
        click: function (modal) { modal.closeModal(); }
      },

      'Work Exceptions': {
        classes: 'red-gradient glossy workExceptions',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}

$.modal.VerificationResultsForTempccPost = function (message, confirmCallback, cancelCallback, options) {
  options = options || {};

  // Cancel callback
  var isConfirmed = false,
    onClose = options.onClose;
  options.onClose = function (event) {
    // Cancel callback
    if (!isConfirmed) {
      cancelCallback.call(this);
    }

    // Previous onClose, if any
    if (onClose) {
      onClose.call(this, event);
    }
  };

  // Open modal
  $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

    content: message,
    buttons: {

      'Post': {
        classes: 'green-gradient glossy postTempCC',
        click: function (modal) { modal.closeModal(); }
      },

      'Work Exceptions': {
        classes: 'red-gradient glossy workExceptions',
        click: function (modal) {
          // Mark as sumbmitted to prevent the cancel callback to fire
          isConfirmed = true;

          // Callback
          confirmCallback.call(modal[0]);

          // Close modal
          modal.closeModal();
        }
      }

    }

  }));
}
function HideStatus($container) {
  /// <summary>
  /// Hide status / progress indicator
  /// </summary>
  /// <param name="$container">Jquery selector for the Container</param>
  var $msg = $container.find(".message");
  if ($msg.length > 0) {
    $msg.hide();
  }
}

function ShowStatus(status, msg, $container) {
  /// <summary>
  /// Show status / progress indicator
  /// </summary>
  /// <param name="status">Possible values : success / inprogress / error</param>
  /// <param name="msg">Message to be displayed along with the progress indicator</param>
  /// <param name="$container">Jquery selector for the Container</param>
  var $msg = $container.find(".message");
  

  if ($msg.length > 0) {
    if ($msg.hasClass("blue-gradient")) {
      $msg.removeClass("blue-gradient");
    }
    else if ($msg.hasClass("red-gradient")) {
      $msg.removeClass("red-gradient");
    }
    else if ($msg.hasClass("green-gradient")) {
      $msg.removeClass("green-gradient");
    }

    if (status == "success") {
      $msg.addClass("green-gradient");
    }
    else if (status == "inprogress") {
      $msg.addClass("blue-gradient");
    }
    else if (status == "error") {
      $msg.addClass("red-gradient");
    }
    else if (status == "warning") {
      $msg.addClass("orange-gradient");
    }
    $msg.show();
    $msg.find(".statusMessage").html(msg);
  }
}

function AdjustTooltipDimensions() {
  /// <summary>
  /// Fix the dimensions of the tooltip so that the text doesn't go beyond the borders.
  /// Assign a class tpComments to the element that is the source of the tooltip.
  /// </summary>
  $(".tpComments").data("tooltip-options", {
    onShow: function (target) {
      //console.log('showing');
      //var p = $("#tooltips");
      var tip = $("#tooltips").find(".message");
      //console.log('HTML : ' + tip.html());

      tip.css("white-space", "normal");
      tip.css("min-width", "150px");
      tip.css("max-width", "300px");

    },
    onRemove: function (target) {
      //console.log('hiding');
      var tip = $("#tooltips").find(".message");
      tip.css("white-space", "nowrap");
      tip.css("min-width", "auto");
    }
  });
}

function ClearValidationMessages() {
  //Clear messages
  $(".formError").each(function () {
    $(this).remove();
  });
}

function onEditorDropDownChange(e) {

  var combo = e.sender;

  // KB: Validate user input on Telerik dropdowns
  if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
    e.preventDefault();
  }

  //get the edited field name
  var fieldName = combo.element.attr("id");
  //find the closest row
  var currentRow = combo.wrapper.closest("tr");
  //find the grid
  var grid = combo.wrapper.closest(".k-grid").data("kendoGrid");
  //get the current row dataItem
  var currentDataItem = grid.dataItem(currentRow);
  //manually set the current value of the DropDownList to the field
  var val = combo.value();

  if (isNaN(val)) {
    currentDataItem.set(fieldName, val);
  }
  else {
    currentDataItem.set(fieldName, parseInt(val));
  }
}

function checkZipCodes(field, rules, i, options) {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="field"></param>
  /// <param name="rules"></param>
  /// <param name="i"></param>
  /// <param name="options"></param>
  /// <returns type=""></returns>
  var errorMessage = "Zip codes must be separated by commas. Please refer to the help text for an example";
  var formatExpression = /^[a-zA-Z0-9\s,]+$/;
  var test = field.val().match(formatExpression);
  if (!test) {
    return errorMessage;
  }
  var zipCodes = field.val().split(',');
  for (var token = 0, l = zipCodes.length; token < l; token++) {
    if (zipCodes[token].length >= 20) {
      return errorMessage;
    }
  }

}

function loadPasswordChange() {
  //alert('Password Expired. Please update your password.');
  winChangePass = $("<div id='winChangePass' />").appendTo(document.body);
  winChangePass.kendoWindow({
    title: "Password Expired !",
    content: '/Account/_ChangeExpiredPassword',
    actions: [],
    modal: true,
    width: 700,
    height: 350,
    deactivate: function () {
      this.destroy();
    },
    close: function (e) {
      return true;
    }
  });
  winChangePass.data('kendoWindow').center().open();
}

//PO Edit Add comment contact scripts
//NP : Service Activity Add Contact Start here
function openAddSRActivityContactWindow(sender, suffixPOID, serviceRequestID) {
  $.ajax({
    type: 'POST',
    url: '/Application/History/_PO_Activity_AddContact', //@Url.Action("_PO_Activity_AddContact", "History", new { area = "Application" })',
    traditional: true,
    data: { ServiceRequestID: serviceRequestID, POID: suffixPOID },
    cache: false,
    ajax: true,
    async: true,
    modal: true,
    success: function (msg) {
      if (IsMyContainerDirty("formAddSRActivityComment_" + suffixPOID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
          CleanMyContainer("formAddSRActivityComment_" + suffixPOID);
          ClearValidationMessages();
          $("#SRCommentType_" + suffixPOID).data('kendoComboBox').select(0);
          $("#SRComments_" + suffixPOID).val(' ');

          $("#divAddSRActivityContact_" + suffixPOID).html(msg);
          $("#divAddSRActivityContact_" + suffixPOID).show();
          $("#divAddSRActivityComment_" + suffixPOID).hide();
          return false;

        }, function () {
          return false;
        });
      }
      else {
        ClearValidationMessages();
        $("#divAddSRActivityContact_" + suffixPOID).html(msg);
        $("#divAddSRActivityContact_" + suffixPOID).show();
        $("#divAddSRActivityComment_" + suffixPOID).hide();
        return false;
      }

    }
  });

}

function HandleSRActivityContactMethodChange(e, suffixPOID, serviceRequestID) {
  var combo = e.sender;
  if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
    e.preventDefault();
    return false;
  }
  ClearValidationMessages();
  var ContactMethodValue = combo.text();
  if (ContactMethodValue == "Phone" || ContactMethodValue == "Text" || ContactMethodValue == "Fax" || ContactMethodValue == "IVR" || ContactMethodValue == "Verbally") {
    $("#divSRActivityAddContactMethodPhone_" + suffixPOID).show();
    $("#divSRActivityAddContactMethodEmail_" + suffixPOID).hide();
  }
  else if (ContactMethodValue == "Email" || ContactMethodValue == "Mail") {
    $("#divSRActivityAddContactMethodEmail_" + suffixPOID).show();
    $("#divSRActivityAddContactMethodPhone_" + suffixPOID).hide();
  }
  else {
    $("#divSRActivityAddContactMethodEmail_" + suffixPOID).hide();
    $("#divSRActivityAddContactMethodPhone_" + suffixPOID).hide();
  }
  return false;
}

function HandleSRContactCategoryChange(e, suffixPOID, serviceRequestID) {
  var combo = e.sender;
  if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
    e.preventDefault();
    return false;
  }
  var contactCategoryID = combo.value();
  var contactReasonMultiSelect = $("#ContactReasonID_" + suffixPOID).data("kendoMultiSelect");
  var contactActionMultiSelect = $("#ContactActionID_" + suffixPOID).data("kendoMultiSelect");
  contactReasonMultiSelect.value('');
  contactActionMultiSelect.value('');
  if (contactCategoryID != null && contactCategoryID != undefined && contactCategoryID > 0) {
    $.ajax({
      type: 'POST',
      url: '/MemberManagement/Member/GetContactActionsAndReasonsForCategory', //'@Url.Action("GetContactActionsAndReasonsForCategory", "Member", new { area = "MemberManagement" })',
      data: { contactCategoryID: contactCategoryID },
      traditional: true,
      cache: false,
      ajax: true,
      async: true,
      modal: true,
      success: function (msg) {
        if (msg.Status == "Success") {
          contactReasonMultiSelect.setDataSource(msg.Data.contactReason);
          contactActionMultiSelect.setDataSource(msg.Data.contactAction);
        }
        else if (msg.Status == "Failure") {
          var ComboInput = "ContactCategory_" + suffixPOID + "_input";
          ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
        }
      }
    });
  }
  else {
    contactReasonMultiSelect.setDataSource([]);
    contactActionMultiSelect.setDataSource([]);
  }
}

function closeAddSRActivityContactWindow(sender, suffixPOID, serviceRequestID) {
  if (IsMyContainerDirty("formAddSRActivityContact_" + suffixPOID)) {
    var message = "Changes will not be saved. Do you want to continue and lose the changes?";
    $.modal.confirm(message, function () {
      CleanMyContainer("formAddSRActivityContact_" + suffixPOID);
      ClearValidationMessages();
      $("#divAddSRActivityContact_" + suffixPOID).hide();
      return false;
    }, function () {
      return false;
    });
  }
  else {
    ClearValidationMessages();
    $("#divAddSRActivityContact_" + suffixPOID).hide();
    return false;
  }

}

function saveAddSRActivityContact(sender, suffixPOID, serviceRequestID) {

  var errorFound = false;
  if ($("#formAddSRActivityContact_" + suffixPOID).validationEngine('validate') == false) {
    errorFound = true;
  }

  var contactCategoryCombo = $("#ContactCategory_" + suffixPOID).data('kendoComboBox');
  var contactCategoryComboInput = "ContactCategory_" + suffixPOID + "_input";
  if ($.trim(contactCategoryCombo.value()).length == 0) {
    ShowValidationMessage($('input[name=' + contactCategoryComboInput + ']'), "* This field is required.");
    errorFound = true;
  }
  else {
    HideValidationMessage($('input[name=' + contactCategoryComboInput + ']'));
  }

  var combo = $("#ContactMethod_" + suffixPOID).data('kendoComboBox');

  var ComboInput = "ContactMethod_" + suffixPOID + "_input";

  if ($.trim(combo.value()).length == 0) {
    ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
    errorFound = true;
  }
  else {
    HideValidationMessage($('input[name=' + ComboInput + ']'));
  }

  var contactReasonMultiSelect = $("#ContactReasonID_" + suffixPOID).data("kendoMultiSelect");
  var contactReasonMultiSelectInput = "#ContactReasonID_" + suffixPOID + "_taglist";

  if (contactReasonMultiSelect.value().length == 0) {
    HideValidationMessage($(contactReasonMultiSelectInput));
    ShowValidationMessage($(contactReasonMultiSelectInput), "* This field is required.");
    errorFound = true;
  }
  else {
    HideValidationMessage($(contactReasonMultiSelectInput));
  }

  var contactActionMultiSelect = $("#ContactActionID_" + suffixPOID).data("kendoMultiSelect");
  var contactActionMultiSelectInput = "#ContactActionID_" + suffixPOID + "_taglist";

  if (contactActionMultiSelect.value().length == 0) {
    HideValidationMessage($(contactActionMultiSelectInput));
    ShowValidationMessage($(contactActionMultiSelectInput), "* This field is required.");
    errorFound = true;
  }
  else {
    HideValidationMessage($(contactActionMultiSelectInput));
  }

  if (errorFound == true) {
    return false;
  }
  var formData = $("#formAddSRActivityContact_" + suffixPOID).serializeArray();

  formData.push({ name: "ContactMethod", value: combo.value() });
  formData.push({ name: "ContactMethodValue", value: combo.text() });

  formData.push({ name: "ContactCategory", value: contactCategoryCombo.value() });
  formData.push({ name: "ContactCategoryValue", value: contactCategoryCombo.text() });

  formData.push({ name: "Email", value: $("#Email_Activity_" + suffixPOID).val() });
  formData.push({ name: "TalkedTo", value: $("#TalkedTo__Activity_" + suffixPOID).val() });
  formData.push({ name: "Notes", value: $("#Notes_" + suffixPOID).val() });
  formData.push({ name: "PhoneNumber", value: GetPhoneNumberForDB("PhoneNumber_Activity_" + suffixPOID) });

  var phoneNumberTypeID = $("#PhoneNumber_Activity_" + suffixPOID + "_ddlPhoneType").val();
  formData.push({ name: "PhoneNumberType", value: phoneNumberTypeID });

  formData.push({ name: "ServiceRequestID", value: serviceRequestID });
  //formData.push({ name: "POID", value: suffixPOID });
  $.ajax({
    type: 'POST',
    url: '/Application/History/SaveSRActivityContact', //'@Url.Action("SaveSRActivityContact", "History", new { area = "Application" })',
    data: formData,
    traditional: true,
    cache: false,
    ajax: true,
    async: true,
    modal: true,
    success: function (msg) {
      if (msg.Status == "Success") {
        CleanMyContainer('formAddSRActivityContact_' + suffixPOID);
        openAlertMessage("Contact Added Successfully");
        $("#divAddSRActivityContact_" + suffixPOID).hide();

        $("#GrdActivity_" + suffixPOID).data('kendoGrid').dataSource.read();
        return false;
      }
    }
  });
  return false;
}

//NP :Service Request Activity Add Contact Ends here

//NP : Service Request Activity Add Comment Start here

function openAddSRActivityCommentWindow(sender, suffixPOID, serviceRequestID) {
  if (IsMyContainerDirty("formAddSRActivityContact_" + suffixPOID)) {
    var message = "Changes will not be saved. Do you want to continue and lose the changes?";
    $.modal.confirm(message, function () {
      $("#divAddSRActivityContact_" + suffixPOID).hide();
      $("#divAddSRActivityComment_" + suffixPOID).show();
      CleanMyContainer("formAddSRActivityContact_" + suffixPOID);
      ClearValidationMessages();
    }, function () {
      return false;
    });
  }
  else {
    ClearValidationMessages();
    $("#divAddSRActivityContact_" + suffixPOID).hide();
    $("#divAddSRActivityComment_" + suffixPOID).show();
    return false;
  }
}

function closeAddSRActivityCommentWindow(sender, suffixPOID, serviceRequestID) {
  ClearValidationMessages();
  if (IsMyContainerDirty("formAddSRActivityComment_" + suffixPOID)) {
    var message = "Changes will not be saved. Do you want to continue and lose the changes?"
    $.modal.confirm(message, function () {
      $("#SRCommentType_" + suffixPOID).data('kendoComboBox').select(0);
      $("#SRComments_" + suffixPOID).val(' ');

      $("#divAddSRActivityComment_" + suffixPOID).hide();
      CleanMyContainer('formAddSRActivityComment_' + suffixPOID);
    }, function () {
      return false;
    });
  }
  else {
    $("#divAddSRActivityComment_" + suffixPOID).hide();
    return false;
  }

}

function saveAddSRActivityComments(sender, suffixPOID, serviceRequestID) {
  var errorFound = false;
  if ($("#formAddSRActivityComment_" + suffixPOID).validationEngine('validate') == false) {
    errorFound = true;
  }

  var combo = $("#SRCommentType_" + suffixPOID).data('kendoComboBox');

  var ComboInput = "SRCommentType_" + suffixPOID + "_input";

  if ($.trim(combo.value()).length == 0) {
    ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
    errorFound = true;
  }
  else {
    HideValidationMessage($('input[name=' + ComboInput + ']'));
  }

  if (errorFound == true) {
    return false;
  }

  var Comments = $("#SRComments_" + suffixPOID).val();
  $.ajax({
    type: 'POST',
    url: '/Application/History/SaveSRActivityComments', //'@Url.Action("SaveSRActivityComments", "History", new { area = "Application" })',
    data: { CommentType: combo.value(), Comments: Comments, ServiceRequestID: serviceRequestID },
    traditional: true,
    cache: false,
    ajax: true,
    async: true,
    modal: true,
    success: function (msg) {
      if (msg.Status == "Success") {
        CleanMyContainer('formAddSRActivityComment_' + suffixPOID);
        openAlertMessage("Comment Added Successfully");

        $("#SRCommentType_" + suffixPOID).data('kendoComboBox').select(0);
        $("#SRComments_" + suffixPOID).val(' ');

        $("#divAddSRActivityComment_" + suffixPOID).hide();
        $("#GrdActivity_" + suffixPOID).data('kendoGrid').dataSource.read();
        return false;
      }
    }

  });
  return false;
}
//NP : Service Request Activity Add Comment Ends here

//KB: START -- UTILITY METHODS FOR HANDLING TAB VALIDATION

function StyleTabAfterValidation(loweredTabName, hasErrors) {

  var $spTab = $('.sp' + loweredTabName);
  if ($spTab.length > 0) {

    if (hasErrors) {
      $spTab.removeClass("icon-tick green").addClass("icon-cross red");
    }
    else {
      $spTab.removeClass("icon-cross red").addClass("icon-tick green");
    }
  }
}

function StyleTabUsingValidationStatus(loweredTabName, validationStatus) {
  var $spTab = $('.sp' + loweredTabName);
  if ($spTab.length > 0) {

    if (validationStatus == '2') {
      $spTab.removeClass("icon-tick green").addClass("icon-cross red");
    }
    else if (validationStatus == '1') {
      $spTab.removeClass("icon-cross red").addClass("icon-tick green");
    }
  }
}

//KB: END -- UTILITY METHODS FOR HANDLING TAB VALIDATION

function SetCheckbox($checkbox, checked) {
  if (checked) {
    $checkbox.attr('checked', true);
    $checkbox.parent().addClass("checked");
  }
  else {
    $checkbox.attr('checked', false);
    $checkbox.parent().removeClass("checked");
  }
}

function SetRadio($radio, checked) {

  if (checked) {
    $radio.attr("checked", true);
    $radio.parent(".radio").addClass("checked");
  }
  else {
    $radio.attr("checked", false);
    $radio.parent(".radio").removeClass("checked");
  }
}

function ResetCombo(combo) {
  combo.setDataSource([]);
  combo.select(0);
  combo.value("");
  combo.text("");
}




$.modal.confirmOkUnlockOpen = function (message,okCallback, unlockCallback, openCallback, options) {
    options = options || {};

    // Cancel callback

    /*
    var isConfirmed = false,
      onClose = options.onClose;
    options.onClose = function (event) {
        // Cancel callback
        if (!isConfirmed) {
            cancelCallback.call(this);
        }

        // Previous onClose, if any
        if (onClose) {
            onClose.call(this, event);
        }
    };
    */

    // Open modal
    $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

        content: message,
        buttons: {

            'Ok': {
                classes: 'silver-gradient glossy',
                click: function (modal) {
                    // Mark as sumbmitted to prevent the cancel callback to fire
                    isConfirmed = true;

                    // Callback
                    okCallback.call(modal[0]);

                    // Close modal
                    modal.closeModal();
                }

            },
            'Unlock': {
                classes: 'blue-gradient glossy',
                click: function (modal) {
                    // Mark as sumbmitted to prevent the cancel callback to fire
                    isConfirmed = true;

                    // Callback
                    unlockCallback.call(modal[0]);

                    // Close modal
                    modal.closeModal();
                }
            },

            'Open': {

                classes: 'green-gradient glossy',
                click: function (modal) {
                    // Mark as sumbmitted to prevent the cancel callback to fire
                    isConfirmed = true;

                    // Callback
                    openCallback.call(modal[0]);

                    // Close modal
                    modal.closeModal();
                }

            }

            

        }

    }));
}