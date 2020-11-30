//Vendor Portal
function ApplyMaskingforVendorInfoSection(vendorID) {
    var taxIDElement = "#TaxEIN_" + vendorID;
    var taxSSNElement = "#TaxSSN_" + vendorID;

    $(taxIDElement).mask("99-9999999");
    $(taxSSNElement).mask("999-99-9999");
}

function GetComboValue(comboName) {
    return $('#' + comboName).data('kendoComboBox').value();
}


// Vendor Tab - Information Section
function SaveVendorInfoTabInformation(sender, suffixVendorID) {

    var errorFoundForVendorInfo = false;
    // Validate all the inputs before Saving the values into DB
    // Get all form Reference first so that we can use it for the validation as well as for Serializing the values.
    var form_Vendor_BasicInformation_Section = "#frmVendorDetailsBasicInformationSection_" + suffixVendorID;

    if ($(form_Vendor_BasicInformation_Section).validationEngine("validate") == false) {
        errorFoundForVendorInfo = true;
    }

    if (!errorFoundForVendorInfo) {

        var basicInformationDataForVendorInfo = $(form_Vendor_BasicInformation_Section).serializeArray();

        // Set values for Kendo Combo Box
        var vendorInfoTaxClassificaiton = $("#TaxClassification_" + suffixVendorID).data('kendoComboBox').value();
        basicInformationDataForVendorInfo.push({ name: "VendorDetails.TaxClassification", value: vendorInfoTaxClassificaiton });

        for (var i = 0, l = basicInformationDataForVendorInfo.length; i < l; i++) {
            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.TaxEIN") {
                basicInformationDataForVendorInfo[i].value = $('#TaxEIN_' + suffixVendorID).mask();
            }
            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.TaxSSN") {
                basicInformationDataForVendorInfo[i].value = $('#TaxSSN_' + suffixVendorID).mask();
            }

            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.IsEmployeeBackgroundChecked_" + suffixVendorID) {
                basicInformationDataForVendorInfo[i].name = "VendorDetails.IsEmployeeBackgroundChecked";
            }
            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.IsEachServiceTruckMarked_" + suffixVendorID) {
                basicInformationDataForVendorInfo[i].name = "VendorDetails.IsEachServiceTruckMarked";
            }
            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.IsDriverUniformed_" + suffixVendorID) {
                basicInformationDataForVendorInfo[i].name = "VendorDetails.IsDriverUniformed";

            }
            if (basicInformationDataForVendorInfo[i].name == "VendorDetails.IsEmployeeDrugTested_" + suffixVendorID) {
                basicInformationDataForVendorInfo[i].name = "VendorDetails.IsEmployeeDrugTested";

            }
        }
        $.ajax({
            type: 'POST',
            url: '/ISP/VendorInfo/SaveVendorInformationSection',
            data: basicInformationDataForVendorInfo,
            success: function (msg) {
                if (msg.Status == "BusinessRuleFail") {
                    openAlertMessage("Must create Levy address or uncheck the Levy checkbox");
                }
                else {
                    // Once the values save to DB Set page to No Dirty and Hide the Buttons
                    CleanMyContainer('frmVendorContainerForDirtyFlag_' + suffixVendorID);
                    //Refresh the page 
                    $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 0);
                }
            }
        });


    }

    return false;
}

function CancelVendorInfoTabInformation(suffixVendorID) {

    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + suffixVendorID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + suffixVendorID);
            //Refresh the page 
            $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 0);
        }, function () {
            // Do Nothing
        });
    }
}

function KendoComboBoxHandleVendorInfoTaxClassificationOther(e, vendorID) {
    var combo = e.sender;
    var relatedTaxClassificationOtherPlaceHolder = "#PlaceHolder_VendorInfo_TaxClassificationOther_" + vendorID;
    var relatedTaxClassificationOtherTextBox = "#TaxClassificationOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }

    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedTaxClassificationOtherPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedTaxClassificationOtherPlaceHolder).addClass('hidden');
        $(relatedTaxClassificationOtherTextBox).val('');
    }
}

function GenericLicenseStateCountryChangeHandler(e, targetName) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var vehicleState = $('#' + targetName).data('kendoComboBox');
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
            var elementState = "input[name='" + targetName + "_input']";
            $(elementState).focus();
            $(elementState).select();

        }
    });
}

// Save and Cancel for Vendor Location Information
function CancelVendorLocationInfSection(vendorID, vendorLocationID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + vendorID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            // Do Nothing 
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
            //Refresh the page 
            $('#VendorLocationDetails_' + vendorLocationID).tabs('load', 0);

        }, function () {
            // Do Nothing
        });
    }
}

function ShowErrorIndicator(message, placeholderName) {
    var Generic_Place_Holder_Ref = $('#' + placeholderName);
    Generic_Place_Holder_Ref.html(message);
    Generic_Place_Holder_Ref.show();
}

function HideErrorIndicator(placeholderName) {
    $('#' + placeholderName).html('').hide();
}

function SaveVendorLocationInfoSection(vendorID, vendorLocationID) {

    var FromForVendorLocationInfo = $('#frmVendorLocationInfoDetails_' + vendorLocationID);
    var IsValidForVendorLocationInfo = true;

    // Validation
    if (FromForVendorLocationInfo.validationEngine("validate") == false) {
        IsValidForVendorLocationInfo = false;
    }

    //Explicitly Insert Combo Box Values into FromDataForVendorLocationInfo
    if (IsValidForVendorLocationInfo) {

        var FromDataForVendorLocationInfo = FromForVendorLocationInfo.serializeArray();

        //For Radio Buttons take out the undercores from name
        for (var i = 0, l = FromDataForVendorLocationInfo.length; i < l; i++) {

            if (FromDataForVendorLocationInfo[i].name == "BasicInformation.IsOpen24Hours_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "BasicInformation.IsOpen24Hours";
            }
            if (FromDataForVendorLocationInfo[i].name == "BasicInformation.IsKeyDropAvailable_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "BasicInformation.IsKeyDropAvailable";
            }

            if (FromDataForVendorLocationInfo[i].name == "BasicInformation.IsOvernightStayAllowed_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "BasicInformation.IsOvernightStayAllowed";
            }

            if (FromDataForVendorLocationInfo[i].name == "BasicInformation.IsElectronicDispatchAvailable_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "BasicInformation.IsElectronicDispatchAvailable";
            }
        }

        FromDataForVendorLocationInfo.push({ name: "AddressInformation.StateProvinceID", value: $("#VendorLocationAddressStateProvinceID_" + vendorLocationID).data('kendoComboBox').value() });
        FromDataForVendorLocationInfo.push({ name: "AddressInformation.CountryID", value: $("#VendorLocationAddressCountryID_" + vendorLocationID).data('kendoComboBox').value() });

        $.ajax({
            type: 'POST',
            url: '/ISP/VendorInfo/_Vendor_Location_Info_Save',
            data: FromDataForVendorLocationInfo,
            success: function (msg) {
                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                CleanMyContainer('frmVendorLocationInfoDetails_' + vendorLocationID);
                //Refresh the page 
                $('#VendorLocationDetails_' + vendorLocationID).tabs('load', 0);
            }
        });


    }
    return false;
}


function HandleBusinessHoursForVendorLocationInfo(sender, vendorLocationID) {
    if ($(sender).val() == "true") {
        $('#PlaceHolder_For_Vendor_Location_Info_BusinessHours_' + vendorLocationID).hide();
    }
    else {
        $('#PlaceHolder_For_Vendor_Location_Info_BusinessHours_' + vendorLocationID).show();
    }
}


// Vendor Services

function CancelVendorServices(suffixVendorID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + suffixVendorID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + suffixVendorID);
            $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 2);

        }, function () {
            return false;
        });
    }
    else {
        $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 2);
    }
}

function SaveVendorServices(suffixVendorID) {
    var postData = $("#frmVendorServices_" + suffixVendorID).serializeArray();
    $.ajax({
        type: 'POST',
        url: '/ISP/VendorServices/SaveVendorServices',
        data: postData,
        success: function (msg) {
            if (msg.Status == "Success") {
                openAlertMessage("Vendor Services Saved");
                CleanMyContainer('frmVendorContainerForDirtyFlag_' + suffixVendorID);
                //Refresh the page 
                $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 2);
            }
            else {
                openAlertMessage(msg.ErrorMessage);
            }
        }
    });
}

// Vendor Location Services

function SaveVendorLocationServices(suffixVendorID, suffixVendorLocationID) {
    var postData = $("#frmVendorLocationServices_" + suffixVendorID).serializeArray();
    $.ajax({
        type: 'POST',
        url: '/ISP/VendorServices/SaveVendorLocationServices',
        data: postData,
        success: function (msg) {
            if (msg.Status == "Success") {
                openAlertMessage("Vendor Services Saved");
                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                CleanMyContainer('frmVendorContainerForDirtyFlag_' + suffixVendorID);
                //Refresh the page 
                $('#VendorLocationDetails_' + suffixVendorLocationID).tabs('load', 2);
            }
            else {
                openAlertMessage(msg.ErrorMessage);
            }
        }
    });
}

function CancelVendorLocationServices(suffixVendorID, suffixVendorLocationID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + suffixVendorID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + suffixVendorID);
            $('#VendorLocationDetails_' + suffixVendorLocationID).tabs('load', 2);

        }, function () {
            return false;
        });
    }
    else {
        $('#VendorLocationDetails_' + suffixVendorLocationID).tabs('load', 2);
    }
}

// For Vendor Locations
function ManageVendorLocations(e, suffixVendorID, grid) {
    if (e != null) {
        e.preventDefault();
        var recordID = grid.dataItem($(e.currentTarget).closest("tr")).VendorLocation;

        if (e.data.commandName == 'Edit') {
            EditVendorLocations(recordID, suffixVendorID);
        }
        else if (e.data.commandName == 'Delete') {
            DeleteVendorLocations(recordID, suffixVendorID);
        }
    }
    else {
        AddVendorLocations(recordID, suffixVendorID);
    }
    return false;
}

function DeleteVendorLocations(recordID, suffixVendorID) {
    $.modal.confirm('Are you sure you want to delete this Vendor Location?', function () {
        $.ajax({
            type: 'POST',
            url: '/ISP/VendorLocation/DeleteVendorLocation',
            traditional: true,
            cache: false,
            data: { vendorLocationID: recordID },
            async: false,
            success: function (msg) {
                $("#GrdVendorLocations_" + suffixVendorID).data('kendoGrid').dataSource.read();
                openAlertMessage('Vendor Location has been deleted successfully');
                BindVendorLocations(suffixVendorID);
            }
        });
    }, function () {

    });
}


function BindVendorLocations(vendorID, val) {
    $.ajax({
        type: 'POST',
        url: '/ISP/VendorLocation/BindVendorLocations',
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        data: { vendorID: vendorID },
        success: function (msg) {
            var vlCombo = $("#VendorLocationID" + vendorID).data('kendoComboBox');
            vlCombo.setDataSource(msg);
            if (val != null) {
                vlCombo.value(val);
                vlCombo.trigger('change');
            }


        }
    });
}
function EditVendorLocations(recordID, suffixVendorID) {
    $("#VendorLocationID" + suffixVendorID).data('kendoComboBox').value(recordID);
    $("#VendorLocationID" + suffixVendorID).data('kendoComboBox').trigger('change');
}

function AddVendorLocations(recordID, suffixVendorID) {
    $.ajax({
        type: 'GET',
        url: '/ISP/VendorLocation/AddVendorLocation',
        traditional: true,
        cache: false,
        async: true,
        data: { VendorID: suffixVendorID },
        success: function (msg) {
            $("#divAddVendorLocation_" + suffixVendorID + "").html(msg);
            $("#divAddVendorLocation_" + suffixVendorID + "").show();
            $("#divVendorLocationsTab_" + suffixVendorID + "").hide();
        }
    });
}

function HandleCountryChange(e, targetDropDown) {

    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var comboChild = $("#" + targetDropDown).data("kendoComboBox");
    if (combo.value() != '' && combo.value() != null) {
        $.ajax({
            type: 'POST',
            url: '/Common/ReferenceData/StateProvinceRelatedToCountry',
            data: { countryId: combo.value() },
            traditional: true,
            cache: false,
            async: true,
            success: function (msg) {
                comboChild.setDataSource(msg);
                comboChild.select(0);
                SetFocusOnField(targetDropDown);
            }

        });
    }
    else {
        comboChild.setDataSource([]);
        comboChild.select(0);
    }
}

function HandleCountryComboChange(sourceDropDown, targetDropDown) {
    var combo = $("#" + sourceDropDown).data("kendoComboBox");
    var comboChild = $("#" + targetDropDown).data("kendoComboBox");
    if (combo.value() != '' && combo.value() != null) {
        $.ajax({
            type: 'POST',
            url: '/Common/ReferenceData/StateProvinceRelatedToCountry',
            data: { countryId: combo.value() },
            traditional: true,
            cache: false,
            async: true,
            success: function (msg) {
                comboChild.setDataSource(msg);
                comboChild.select(0);
            }

        });
    }
    else {
        comboChild.setDataSource([]);
        comboChild.select(0);
    }
}

function CancelAddVendorLocation(vendorID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + vendorID)) {
        var message = "Changes have not been saved; Do you want to continue and lose the changes?"
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
            $("#divVendorLocationsTab_" + vendorID).show();
            $("#divAddVendorLocation_" + vendorID).hide();
      
        }, function () {

        });
    }
    else {
        CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
        $("#divAddVendorLocation_" + vendorID).hide();
        $("#divVendorLocationsTab_" + vendorID).show();
    }
}


function SaveAddVendorLocation(vendorID, isEdit) {

    var formElement = "#frmAddVendorLocation_" + vendorID;
    var errorfound = false;
    if ($(formElement).validationEngine("validate") == false) {
        errorfound = true;
    }
    var countryCombo = "LocationCountry_" + vendorID;
    var country = $("#" + countryCombo).data('kendoComboBox').value();
    if ($.trim(country).length == 0) {
        ShowValidationMessage($('input[name= "' + countryCombo + '_input"]'), "* This field is required.");
        errorfound = true;
    }
    else {
        HideValidationMessage($('input[name= "' + countryCombo + '_input"]'));
    }

    var stateCombo = "LocationState_" + vendorID;
    var state = $("#" + stateCombo).data('kendoComboBox').value();
    if ($.trim(state).length == 0) {
        ShowValidationMessage($('input[name= "' + stateCombo + '_input"]'), "* This field is required.");
        errorfound = true;
    }
    else {
        HideValidationMessage($('input[name= "' + stateCombo + '_input"]'));
    }

    if (errorfound == true) {
        return false;
    }
    var formData = $("#frmAddVendorLocation_" + vendorID + "").serializeArray();
    formData.push({ name: "LocationAddress1", value: $("#LocationAddress1_" + vendorID + "").val() });
    formData.push({ name: "LocationAddress2", value: $("#LocationAddress2_" + vendorID + "").val() });
    formData.push({ name: "LocationAddress3", value: $("#LocationAddress3_" + vendorID + "").val() });
    formData.push({ name: "LocationCity", value: $("#LocationCity_" + vendorID + "").val() });
    formData.push({ name: "LocationPostalCode", value: $("#LocationPostalCode_" + vendorID + "").val() });
    formData.push({ name: "LocationDispatchNumber", value: GetPhoneNumberForDB("LocationDispatchNumber_" + vendorID + "") });
    formData.push({ name: "LocationFaxNumber", value: GetPhoneNumberForDB("LocationFaxNumber_" + vendorID + "") });
    formData.push({ name: "LocationCountryValue", value: $("#LocationCountry_" + vendorID + "").data('kendoComboBox').text() });
    formData.push({ name: "LocationStateValue", value: $("#LocationState_" + vendorID + "").data('kendoComboBox').text() });
    formData.push({ name: "LocationCountry", value: $("#LocationCountry_" + vendorID + "").data('kendoComboBox').value() });
    formData.push({ name: "LocationState", value: $("#LocationState_" + vendorID + "").data('kendoComboBox').value() });
    formData.push({ name: "VendorID", value: vendorID });

    $.ajax({
        type: 'POST',
        url: '/ISP/VendorLocation/SaveVendorLocation',
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        data: formData,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
                openAlertMessage('Location Added Successfully');
                $("#GrdVendorLocations_" + vendorID).data('kendoGrid').dataSource.read();
                $("#divAddVendorLocation_" + vendorID).hide();
                $("#divVendorLocationsTab_" + vendorID).show();
                if (isEdit) {
                    BindVendorLocations(vendorID, msg.Data);
                }
                else {
                    BindVendorLocations(vendorID);
                }
            }
        }
    });         // end of ajax

}


function HandleLocationListChange(e, suffixVendorID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if (combo.value() != '' && combo.value() != null) {
        $.ajax({
            type: 'POST',
            url: '/ISP/VendorLocation/GetVendorLocationAddress',
            data: { vendorLocationID: combo.value() },
            traditional: true,
            cache: false,
            async: true,
            success: function (msg) {
                if (msg.Status == "Success") {
                    var lca = msg.Data;
                    $("#LocationAddress1_" + suffixVendorID + "").val(lca.LocationAddress1);
                    $("#LocationAddress2_" + suffixVendorID + "").val(lca.LocationAddress2);
                    $("#LocationAddress3_" + suffixVendorID + "").val(lca.LocationAddress3);
                    $("#LocationCity_" + suffixVendorID + "").val(lca.LocationCity);
               
                    $("#LocationPostalCode_" + suffixVendorID + "").val(lca.LocationPostalCode);
                    if (lca.LocationDispatchNumber != null && lca.LocationDispatchNumber != undefined && lca.LocationDispatchNumber != "") {
                        SetPhoneValues("#LocationDispatchNumber_" + suffixVendorID, "+" + lca.LocationDispatchNumber, false);
                    }
                    if (lca.LocationFaxNumber != null && lca.LocationFaxNumber != undefined && lca.LocationFaxNumber != "") {
                        SetPhoneValues("#LocationFaxNumber_" + suffixVendorID, "+" + lca.LocationFaxNumber, false);
                    }
                    $("#LocationCountry_" + suffixVendorID).data('kendoComboBox').value(lca.LocationCountry);

                    CascadeStateFromCountryAndSetValue(suffixVendorID, lca.LocationState);
                }
            }
        });
    }
    else {
        $("#LocationAddress1_" + suffixVendorID + "").val('');
        $("#LocationAddress2_" + suffixVendorID + "").val('');
        $("#LocationAddress3_" + suffixVendorID + "").val('');
        $("#LocationCity_" + suffixVendorID + "").val('');
        $("#LocationPostalCode_" + suffixVendorID + "").val('');

        $("#LocationCountry_" + suffixVendorID).data('kendoComboBox').value('');
        $("#LocationCountry_" + suffixVendorID).data('kendoComboBox').text('');
        $("#LocationCountry_" + suffixVendorID).data('kendoComboBox').trigger('change');

        $("#LocationState_" + suffixVendorID).data('kendoComboBox').value('');
        $("#LocationState_" + suffixVendorID).data('kendoComboBox').text('');
        $("#LocationState_" + suffixVendorID).data('kendoComboBox').trigger('change');

        SetPhoneValues("#LocationFaxNumber_" + suffixVendorID, "+", false);
        SetPhoneValues("#LocationDispatchNumber_" + suffixVendorID, "+", false);
    }
}

function CascadeStateFromCountryAndSetValue(suffixVendorID, stateID) {
    var countryCombo = $('#LocationCountry_' + suffixVendorID).data('kendoComboBox'); ;
    var stateCombo = $('#LocationState_' + suffixVendorID).data('kendoComboBox');
    $.ajax({
        type: 'POST',
        url: '/Common/ReferenceData/StateProvinceRelatedToCountry',
        traditional: true,
        data: { countryId: countryCombo.value() },
        cache: false,
        async: true,
        success: function (msg) {
            stateCombo.setDataSource(msg);
            stateCombo.value(stateID);
        }
    });
}


function HandleVendorLocationForRatesDropDown(e, suffixVendorID) {
    var combo = e.sender; 
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    $('#GrdVendorServiceRates_' + suffixVendorID).data('kendoGrid').dataSource.read();
}