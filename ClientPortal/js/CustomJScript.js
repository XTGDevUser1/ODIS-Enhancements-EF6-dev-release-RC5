function openAlertMessage(alertMessage) {
    $.modal.alert(alertMessage, {
        buttons: {
            'OK': {
                classes: 'huge blue-gradient glossy full-width',
                click: function (win) { win.closeModal(); }
            }
        }
    });
}

// Put the first editable input control in to focus.
$(function () {
    setTimeout(function () {

        var firstField = $("form").find("input[type=text]").not(":disabled").not("[readonly]").first(); //$("input[type=text]").first();
        firstField.focus();
    }, 1000);

});

var queueDetailWindow;
function ShowServiceRequestDetails(actionURL, id, popupTitle, isEditRequired) {

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

//var queueDetailWindow;
//function ShowServiceRequestDetails(actionURL, id, popupTitle, isEditRequired) {

//    mode = "edit";
//    title = "Service Request ID: " + id;
//    $.ajax({
//        type: 'POST',
//        url: actionURL,
//        traditional: true,
//        data: { queueId: id, fromStartCall: true, isEditRequired: isEditRequired },
//        cache: false,
//        async: false,
//        success: function (msg) {
//            queueDetailWindow = $.telerik.window.create({
//                title: title,
//                html: msg,
//                modal: true,
//                width: 1200,
//                height: GetPopupWindowHeight(),
//                onClose: function () {
//                    if (document.dialogResult == null || document.dialogResult == "CANCEL") {
//                        document.dialogResult = null;
//                        if (!IsPageDirty()) {
//                            return false;
//                        }
//                    }
//                    isdirty = false;
//                    $(this).remove();
//                    return true;
//                }
//            });
//            queueDetailWindow.data('tWindow').center().open();
//        } // end of success callback
//    }); // end of ajax
//}
/* FOR ADDRESSES */

function AddressesGrid(grid) {
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
function GetFormattedPhoneNumber(phoneNumber, regionCode) {
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
    var number = phoneUtil.parseAndKeepRawInput(fullPhoneNumber, null);
    var regionCode = phoneUtil.getRegionCodeForNumber(number);

    if (isReadOnly) {
        var formattedNumber = GetFormattedPhoneNumber(fullPhoneNumber, regionCode);
        $(prefix + '_lblPhoneNumber').html(formattedNumber);
    }
    else {
        // Set the selected value in the dropdown.
        //var $countryCode = $(prefix + 'txtPhoneNumber');
        $(prefix + "_ddlCountryCode option").each(function () {
            if ($(this).text() == regionCode) {
                $(this).attr('selected', 'selected');
            }
        });
        var telephoneNumber = GetFormattedPhoneNumberWithoutCountryCode(number.getNationalNumber().toString(), regionCode);
        var extension = number.getExtension();
        // Set these on the textfields
        $(prefix + '_txtPhoneNumber').val(telephoneNumber);
        $(prefix + '_txtExtension').val(extension);
    }
}

function GetPhoneNumberFromFormat(fullPhoneNumberFromDB) {

    var fullPhoneNumber = "+" + fullPhoneNumberFromDB;
    var number = phoneUtil.parseAndKeepRawInput(fullPhoneNumber, null);
    return number;

}
function GetPhoneNumberForDB(phoneElementFor) {
    try {

        var $countryCode = $("#" + phoneElementFor + "_ddlCountryCode");
        if ($countryCode.length > 0) // We have text boxes
        {
            var $phoneNumber = $("#" + phoneElementFor + "_txtPhoneNumber");
            var $extension = $("#" + phoneElementFor + "_txtExtension");


            var regionCode = $countryCode.find("option:selected").text();
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
    
    var $countryCode = field.parents(".phone-input").find(".countryCode");
    var phoneNumber = field.val();
    var regionCode = $countryCode.find("option:selected").text();

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
/* Regex approach 
    var regex = /^(0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d$/;
    var test = field.val().match(regex);.
*/
    if ($.trim(field.val()).length > 0) {
        var test = Date.parseExact(field.val(), "MM/dd/yyyy");
        if (!test) {
            return "Invalid date. Enter date in MM/DD/YYYY format";
        }
    }
}

function checkEmail(emailText)
{
    var regex = { "expression": /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i };
    var test = emailText.match(regex.expression);
    if(!test)
    {
        return false;
    }
    return true;

}

function CheckFutureDate(field, rules, i, options) {
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

function ShowValidationMessage(element, message) {

    var id = element.attr("id");
    if (id == null) {
        var name = element.attr("name");
        if (name != undefined) {
            name = name.replace(".", "_");
            element.attr("id", name + "-jqv");
        }
    }
    element.validationEngine('showPrompt', message, '', 'topRight', true);
}
function HideValidationMessage(element) {
    
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
    var date1 = Date.parseExact(d1, format);
    var date2 = Date.parseExact(d2, format);
    return date1.compareTo(date2);
}

function FormatPhoneNumber(table, colIndex) {
    
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
    
    MarkPageAsDirty(combo.element);
    return isValidSelection;
}

// This method is used to validate if the user typed an entry that is in the allowed set of values.
// If the user input is not in the allowed set of values, then the value and text properties of the dropdown are reset.
function IsUserInputValidForChangeOnKendoCombo(combo) {    
    var isValidSelection = true;
    var inputLength = combo.text().length;
    if (combo.select() < 0) {
        combo.value('');
        combo.text('');
        combo.search('');
        
        if (inputLength == 0) {
            return true;
        }
        
        return false;
    }

    if (combo.value() == "Select") {
        combo.value("");
    }    

    MarkPageAsDirty(combo.element);
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
function ValidateInputForKendoCombo(e) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
}

/* Kendo Grid error handler */
function KendoGridErrorHandler(e) {
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
    $gridElement.delegate("tbody>tr", "dblclick", function () {
        $(this).find(buttonClass).click();
    });
}
