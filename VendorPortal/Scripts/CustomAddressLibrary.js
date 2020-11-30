function SwitchViewToEdit(addressID, recordID, entityName) {
    GetAddressDetails(addressID, recordID, entityName);
}

function ReloadAddressList(recordID, entityName) {
    $.ajax({
        url: '/Common/Addresses/GetScrollableAddressList',
        type: 'GET',
        data: { recordID: recordID, entityName: entityName },
        success: function (msg) {

            var addressPlaceHolder = '#PlaceHolder_Address_' + recordID;
            var addressContainerPlaceHolder = '#PlaceHolder_AddressContainer_' + recordID;
            var newAddressIcon = "#PlaceHolder_AddressNew_" + recordID;

            $(addressPlaceHolder).removeClass('hidden');
            $(addressPlaceHolder).html(msg);
            $(newAddressIcon).removeClass('hidden');
            $(addressContainerPlaceHolder).addClass('hidden');
            $(addressContainerPlaceHolder).html('');
        }
    });
}

function SwitchViewToCancel(recordID) {

    $('#form_Address_' + recordID).validationEngine("hideAll");

    var addressPlaceHolder = '#PlaceHolder_Address_' + recordID;
    var addressContainerPlaceHolder = '#PlaceHolder_AddressContainer_' + recordID;
    var newAddressIcon = "#PlaceHolder_AddressNew_" + recordID;

    $(addressContainerPlaceHolder).addClass('hidden');
    $(addressPlaceHolder).removeClass('hidden');
    $(newAddressIcon).removeClass('hidden');
    $(addressContainerPlaceHolder).html('');
}

function GetAddressDetails(addressID, recordID, entityName) {
    $.ajax({
        url: '/Common/Addresses/_GetAddressDetails',
        data: { recordID: recordID, entityName: entityName, addressID: addressID },
        success: function (msg) {

            var addressPlaceHolder = '#PlaceHolder_Address_' + recordID;
            var addressContainerPlaceHolder = '#PlaceHolder_AddressContainer_' + recordID;
            var newAddressIcon = "#PlaceHolder_AddressNew_" + recordID;

            $(addressContainerPlaceHolder).removeClass('hidden');
            $(addressPlaceHolder).addClass('hidden');
            $(newAddressIcon).addClass('hidden');
            $(addressContainerPlaceHolder).html(msg);
        }
    });
}

function ValidateInputForKendoComboWithHide(e) {
    var combo = e.sender;

    var element = "input[name=" + this.element.attr("id") + "_input]";
    HideValidationMessage($(element));

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
}

function LicenseStateCountryChange(e, recordID) {

    var elementState = "input[name=StateProvince_" + recordID + "_input]";
    var elementCountry = "input[name=CountryID_" + recordID + "_input]";

    HideValidationMessage($(elementState));
    HideValidationMessage($(elementCountry));

    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var vehicleState = $('#StateProvinceID_' + recordID).data('kendoComboBox');
    $.ajax({
        type: 'GET',
        url: '/Common/ReferenceData/GetStateProvinceWithID',
        traditional: true,
        data: { countryID: combo.value() },
        cache: false,
        async: true,
        success: function (msg) {
            vehicleState.setDataSource(msg);
            vehicleState.select(0);
            var elementState = "input[name='StateProvinceID_" + recordID + "_input']";
            $(elementState).focus();
            $(elementState).select();

        }
    });
}

function ValidateCombo(elementID) {
    var elementRef = $('#' + elementID).data('kendoComboBox').value();
    var elementTextBox = "input[name='" + elementID + "_input']";

    if ($.trim(elementRef).length == 0) {
        ShowValidationMessage($(elementTextBox), "* This field is required.");
        return false;
    }
    else {
        HideValidationMessage($(elementTextBox));
    }

    return true;
}

function DeleteAddress(addressID, recordID, entityName) {
    $.modal.confirm('The address will be permanently removed; are you sure you want to delete this address?', function () {
        $.ajax({
            type: 'POST',
            url: '/Common/Addresses/DeleteAddress',
            data: { addressID: addressID },
            traditional: true,
            cache: false,
            success: function (msg) {
                ReloadAddressList(recordID, entityName);
            }
        });
    }, function () {

    });
}

function SaveAddressDetails(recordID, entityName) {
    var errorfound = false;

    //Validate Form
    if ($('#form_Address_' + recordID).validationEngine("validate") == false) {
        errorfound = true;
    }
    //Validate Address Type
    if (!ValidateCombo('AddressTypeID_' + recordID)) {
        errorfound = true;
    }

    //Validate Country
    if (!ValidateCombo('CountryID_' + recordID)) {
        errorfound = true;
    }

    //Validate State
    if (!ValidateCombo('StateProvinceID_' + recordID)) {
        errorfound = true;
    }

    if (!errorfound) {
        //Write code to Save Address to DB
        var postData = $('#form_Address_' + recordID).serializeArray();

        postData.push({ name: "AddressTypeID", value: $('#AddressTypeID_' + recordID).data('kendoComboBox').value() });
        postData.push({ name: "CountryID", value: $('#CountryID_' + recordID).data('kendoComboBox').value() })
        postData.push({ name: "CountryCode", value: $('#CountryID_' + recordID).data('kendoComboBox').text() })
        postData.push({ name: "StateProvince", value: $('#StateProvinceID_' + recordID).data('kendoComboBox').text() })
        postData.push({ name: "StateProvinceID", value: $('#StateProvinceID_' + recordID).data('kendoComboBox').value() })

        $.ajax({
            type: 'POST',
            url: '/Common/Addresses/SaveAddressDetailsFor',
            data: postData,
            traditional: true,
            cache: false,
            success: function (msg) {
                ReloadAddressList(recordID, entityName);
            }
        });
    }
    return false;
}