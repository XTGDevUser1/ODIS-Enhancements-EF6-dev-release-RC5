
function GetComboValue(comboName) {
    return $('#' + comboName).data('kendoComboBox').value();
}


function ComboHandleEmailForVendorACH(e, vendorID) {
    var combo = e.sender;
    var relatedVendorACHEmailPlaceHolder = "#PlaceHolder_For_Vendor_ACH_EMAIL_" + vendorID;
    var relatedVendorACHEmailTextBox = "#ReceiptEmail_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }

    if ($.trim(combo.text()).length > 0 && combo.text() == "Email") {
        $(relatedVendorACHEmailPlaceHolder).show();
    }
    else {
        $(relatedVendorACHEmailPlaceHolder).hide();
        $(relatedVendorACHEmailTextBox).val('');
    }
}

function CancelVendorACHTabInformation(suffixVendorID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + suffixVendorID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {

            //Hide Validation Message
            $('#frmVendorACHDetails_' + suffixVendorID).validationEngine("hideAll");
            // Do Nothing 
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + suffixVendorID);
            //Refresh the page 
            $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 6);

        }, function () {
            // Do Nothing
        });
    }
}

function LicenseStateCountryChangeGroupACH(e, recordID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var vehicleState = $('#BankAddressStateProvinceID_' + recordID).data('kendoComboBox');
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
            var elementState = "input[name='BankAddressStateProvinceID_" + recordID + "_input']";
            $(elementState).focus();
            $(elementState).select();

        }
    });
}

function SaveVendorACHTabInformation(suffixVendorID) {

    var achTabValidated = true;
    var form_Vendor_ACH_Section = "#frmVendorACHDetails_" + suffixVendorID;
    var Combo_Vendor_ACH_Section_AccountType = "AccountType_" + suffixVendorID;
    var Combo_Vendor_ACH_Section_ACHStatus = "ACHStatusID_" + suffixVendorID;
    var Combo_Vendor_ACH_Section_ReceiptMethod = "ReceiptContactMethodID_" + suffixVendorID;
    var Combo_Vendor_ACH_Section_Country = "BankAddressCountryID_" + suffixVendorID;
    var Combo_Vendor_ACH_Section_State = "BankAddressStateProvinceID_" + suffixVendorID;

    if ($(form_Vendor_ACH_Section).validationEngine("validate") == false) {
        achTabValidated = false;
    }
    if (!ValidateCombo(Combo_Vendor_ACH_Section_AccountType)) {
        achTabValidated = false;
    }
    if (!ValidateCombo(Combo_Vendor_ACH_Section_ACHStatus)) {
        achTabValidated = false;
    }
    if (!ValidateCombo(Combo_Vendor_ACH_Section_ReceiptMethod)) {
        achTabValidated = false;
    }

    //Email is Required only if the type selected is Email.
    if ($('#' + Combo_Vendor_ACH_Section_ReceiptMethod).data('kendoComboBox').text() == "Email") {
        var emailValueForACHVendor = $.trim($('#ReceiptEmail_' + suffixVendorID).val());
        var elementEmailTextBoxForACHVendor = "input[id='ReceiptEmail_" + suffixVendorID + "']";
        if (emailValueForACHVendor.length == 0) {
            achTabValidated = false;
            ShowValidationMessage($(elementEmailTextBoxForACHVendor), "This field is required.");
        }
        else {
            HideValidationMessage($(elementEmailTextBoxForACHVendor));
        }
    }

    if (achTabValidated) {
        var postData = $(form_Vendor_ACH_Section).serializeArray();
        postData.push({ name: "VendorACHDetails.AccountType", value: GetComboValue(Combo_Vendor_ACH_Section_AccountType) });
        postData.push({ name: "VendorACHDetails.ACHStatusID", value: GetComboValue(Combo_Vendor_ACH_Section_ACHStatus) });
        postData.push({ name: "VendorACHDetails.ReceiptContactMethodID", value: GetComboValue(Combo_Vendor_ACH_Section_ReceiptMethod) });
        postData.push({ name: "VendorACHDetails.BankAddressCountryID", value: GetComboValue(Combo_Vendor_ACH_Section_Country) });
        postData.push({ name: "VendorACHDetails.BankAddressStateProvinceID", value: GetComboValue(Combo_Vendor_ACH_Section_State) });
        postData.push({ name: "VendorACHDetails.BankPhoneNumber", value: GetPhoneNumberForDB('ACHBankPhoneNumber_' + suffixVendorID) });

        $.ajax({
            type: 'POST',
            url: '/VendorManagement/VendorHome/SaveVendorACHSection',
            data: postData,
            success: function (msg) {
                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                CleanMyContainer('frmVendorContainerForDirtyFlag_' + suffixVendorID);
                //Refresh the page 
                $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 6);
            }
        });
    }

    return false;
}

// Vendor Tab - Information Section
function SaveVendorInfoTabInformation(sender, suffixVendorID) {

    var errorFoundForVendorInfo = false;
    // Validate all the inputs before Saving the values into DB
    // Get all form Reference first so that we can use it for the validation as well as for Serializing the values.
    var form_Vendor_BasicInformation_Section = "#frmVendorDetailsBasicInformationSection_" + suffixVendorID;
    var form_Vendor_QualityIndicatios_Section = "#frmVendorDetailsQualityIndicatorsSection_" + suffixVendorID;
    var form_Vendor_Insurance_Section = "#frmVendorDetailsInsuranceSection_" + suffixVendorID;
    var form_Vendor_Dispatch_Software_Section = "#frmVendorDetailsDispatchSoftwareSection_" + suffixVendorID;
    var Combo_Vendor_Info_Status = "VendorStatusID_" + suffixVendorID;

    if ($(form_Vendor_BasicInformation_Section).validationEngine("validate") == false) {
        errorFoundForVendorInfo = true;
    }

    if ($(form_Vendor_QualityIndicatios_Section).validationEngine("validate") == false) {
        errorFoundForVendorInfo = true;
    }

    if ($(form_Vendor_Insurance_Section).validationEngine("validate") == false) {
        errorFoundForVendorInfo = true;
    }

    if ($(form_Vendor_Dispatch_Software_Section).validationEngine("validate") == false) {
        errorFoundForVendorInfo = true;
    }

    if (!ValidateCombo(Combo_Vendor_Info_Status)) {
        errorFoundForVendorInfo = true;
        return false;
    }

    // Check to See if the User have changed Vendor Status then Change Reason id Required
    var Vendor_Status_Old_Value = $('#OldVendorStatusID_' + suffixVendorID).val();
    var Vendor_Status_New_Value = $("#VendorStatusID_" + suffixVendorID).data('kendoComboBox').value();

    if (Vendor_Status_Old_Value != undefined && Vendor_Status_Old_Value != Vendor_Status_New_Value) {
        var Combo_Vendor_Status_Change_Reson = "VendorChangeReasonID_" + suffixVendorID;
        if (!ValidateCombo(Combo_Vendor_Status_Change_Reson)) {
            errorFoundForVendorInfo = true;
        }
    }


    if (!errorFoundForVendorInfo) {

        var basicInformationDataForVendorInfo = $(form_Vendor_BasicInformation_Section).serializeArray();
        var qualityIndicatiorsDataForVendorInfo = $(form_Vendor_QualityIndicatios_Section).serializeArray();
        var insuranceDataForVendorInfo = $(form_Vendor_Insurance_Section).serializeArray();
        var dispatchSoftwareDataForVendorInfo = $(form_Vendor_Dispatch_Software_Section).serializeArray();
        var completeData = basicInformationDataForVendorInfo;
        completeData = $.merge(completeData, qualityIndicatiorsDataForVendorInfo);
        completeData = $.merge(completeData, insuranceDataForVendorInfo);
        completeData = $.merge(completeData, dispatchSoftwareDataForVendorInfo);

        // Set values for Kendo Combo Box
        var vendorLocationID = $("#VendorLocationID" + suffixVendorID).data('kendoComboBox').value();
        var vendorStatusID = $("#VendorStatusID_" + suffixVendorID).data('kendoComboBox').value();
        var vendorChangedReasonID = $("#VendorChangeReasonID_" + suffixVendorID).data('kendoComboBox').value();
        var vendorInfoTaxClassificaiton = $("#TaxClassification_" + suffixVendorID).data('kendoComboBox').value();

        var vendorInfoDispatchSoftware = $("#DispatchSoftwareProductID_" + suffixVendorID).data('kendoComboBox').value();
        var vendorInfoDriverSoftware = $("#DriverSoftwareProductID_" + suffixVendorID).data('kendoComboBox').value();
        var vendorInfoDispatchGPS = $("#DispatchGPSNetworkID_" + suffixVendorID).data('kendoComboBox').value();

        completeData.push({ name: "BasicInformation.VendorStatusID", value: vendorStatusID });
        completeData.push({ name: "ChangeResonID", value: vendorChangedReasonID });
        completeData.push({ name: "VendorLocationID", value: vendorLocationID });
        completeData.push({ name: "BasicInformation.TaxClassification", value: vendorInfoTaxClassificaiton });

        completeData.push({ name: "BasicInformation.DispatchSoftwareProductID", value: vendorInfoDispatchSoftware });
        completeData.push({ name: "BasicInformation.DriverSoftwareProductID", value: vendorInfoDriverSoftware });
        completeData.push({ name: "BasicInformation.DispatchGPSNetworkID", value: vendorInfoDispatchGPS });

        for (var i = 0, l = completeData.length; i < l; i++) {
            if (completeData[i].name == "BasicInformation.TaxEIN") {
                completeData[i].value = $('#TaxEIN_' + suffixVendorID).mask();
            }
            if (completeData[i].name == "BasicInformation.TaxSSN") {
                completeData[i].value = $('#TaxSSN_' + suffixVendorID).mask();
            }

            if (completeData[i].name == "BasicInformation.IsEmployeeBackgroundChecked_" + suffixVendorID) {
                completeData[i].name = "BasicInformation.IsEmployeeBackgroundChecked";
            }
            if (completeData[i].name == "BasicInformation.IsEachServiceTruckMarked_" + suffixVendorID) {
                completeData[i].name = "BasicInformation.IsEachServiceTruckMarked";
            }
            if (completeData[i].name == "BasicInformation.IsDriverUniformed_" + suffixVendorID) {
                completeData[i].name = "BasicInformation.IsDriverUniformed";

            }
            if (completeData[i].name == "BasicInformation.IsEmployeeDrugTested_" + suffixVendorID) {
                completeData[i].name = "BasicInformation.IsEmployeeDrugTested";

            }

        }

        $.ajax({
            type: 'POST',
            url: '/VendorManagement/VendorHome/SaveVendorInformationSection',
            data: completeData,
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
            // Do Nothing
            // Do Nothing 
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + suffixVendorID);
            //Refresh the page 
            $('#VendorDetailsTab_' + suffixVendorID).tabs('load', 0);
        }, function () {
            // Do Nothing
        });
    }
}


function HandleVendorQualityIndicators(sender, vendorID) {
    var element = $(sender);
    var elementID = element.attr('id').replace("_" + vendorID, "");
    var selectedValue = element.val();

    var commentTextBox = '#' + elementID + "Comment_" + vendorID;
    var placeHolder = "#PlaceHolder_" + elementID + "_" + vendorID;

    if (selectedValue == "true") {
        $(commentTextBox).val('');
        $(placeHolder).addClass('hidden');
    }
    else {
        $(placeHolder).removeClass('hidden');
    }
}

function HandleVendorBasicInformationLevy(vendorID) {
    var placeHolder = "#PlaceHolder_Vendor_Basic_Info_Levy_" + vendorID;
    var relatedTextBox = "#LevyRecipientName_" + vendorID;
    var element = '#IsLevyActive_' + vendorID;
    if ($(element).is(":checked")) {
        $(placeHolder).removeClass('hidden');
        $(relatedTextBox).addClass("validate[required]");
    }
    else {
        $(relatedTextBox).val('');
        $(placeHolder).addClass('hidden');
        $(relatedTextBox).removeClass("validate[required]");
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

function KendoComboBoxHandleVendorStatusChangeReson(e, vendorID) {

    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_StatusChangesReasonOther_" + vendorID;
    var changedReasonOtherTextBox = "#ChangedReasonOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedPlaceHolder).addClass('hidden');
        $(changedReasonOtherTextBox).val('');
    }
}


function KendoComboBoxHandleVendorInfoDispatchSoftwareOther(e, vendorID) {

    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_DispatchSoftwareProductOther_" + vendorID;
    var changedDispatchSoftwareOtherTextBox = "#DispatchSoftwareProductOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedPlaceHolder).addClass('hidden');
        $(changedDispatchSoftwareOtherTextBox).val('');
    }
}

function KendoComboBoxHandleVendorInfoDriverSoftwareOther(e, vendorID) {

    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_DriverSoftwareProductOther_" + vendorID;
    var changedDriverSoftwareOtherTextBox = "#DriverSoftwareProductOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedPlaceHolder).addClass('hidden');
        $(changedDriverSoftwareOtherTextBox).val('');
    }
}

function KendoComboBoxHandleVendorInfoDispatchGPSNetworkOther(e, vendorID) {

    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_DispatchGPSNetworkOther_" + vendorID;
    var changedDispatchGPSNetworkOtherTextBox = "#DispatchGPSNetworkOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedPlaceHolder).addClass('hidden');
        $(changedDispatchGPSNetworkOtherTextBox).val('');
    }
}

function KendoComboBoxForVendorStatusChange(e, vendorID, previousValue) {
    var combo = e.sender;

    var relatedPlaceHolder = "#PlaceHolder_StatusChange_" + vendorID;
    var changedReasonDropDown = "#VendorChangeReasonID_" + vendorID;
    var changedReasonCommentTextBox = "#ChangeReasonComments_" + vendorID;
    var changedReasonOtherTextBox = "#ChangedReasonOther_" + vendorID;
    var changedReasonOtherPlaceHolder = "#PlaceHolder_StatusChangesReasonOther_" + vendorID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var newValue = combo.value();
    if (newValue != undefined && newValue.length > 0) {
        if (newValue != previousValue) {
            $(relatedPlaceHolder).removeClass('hidden');
            var elementState = "input[name='VendorChangeReasonID_" + vendorID + "_input']";
            $(elementState).focus();
            $(elementState).select();
        }
        else {
            $(relatedPlaceHolder).addClass('hidden');
            $(changedReasonDropDown).data('kendoComboBox').select(0);
            $(changedReasonCommentTextBox).val('');
            $(changedReasonOtherTextBox).val('');
            var elementState = "#Name_" + vendorID;
            $(elementState).focus();
            $(elementState).select();
        }
    }
}

// Script for Vendor Location Information Tabs
function KendoComboBoxForVendorLocationStatusChange(e, vendorlocationID, previousValue) {
    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_VendorLocationVendorStatusChange_" + vendorlocationID;
    var changedReasonDropDown = "#VendorLocationChangeReasonID_" + vendorlocationID;
    var changedReasonCommentTextBox = "#VendorLocationChangeReasonComments_" + vendorlocationID;
    var changedReasonOtherTextBox = "#VendorLocationChangeReasonOther_" + vendorlocationID;
    var changedReasonOtherPlaceHolder = "#PlaceHolder_VendorLocationStatusChangesReasonOther_" + vendorlocationID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var newValue = combo.value();
    if (newValue != undefined && newValue.length > 0) {
        if (newValue != previousValue) {
            $(relatedPlaceHolder).removeClass('hidden');
            var elementState = "input[name='VendorLocationChangeReasonID_" + vendorlocationID + "_input']";
            $(elementState).focus();
            $(elementState).select();
        }
        else {
            $(relatedPlaceHolder).addClass('hidden');
            $(changedReasonDropDown).data('kendoComboBox').select(0);
            $(changedReasonCommentTextBox).val('');
            $(changedReasonOtherTextBox).val('');
        }
    }
}

function KendoComboBoxHandleVendorLocationStatusChangeReson(e, vendorLocationID) {
    var combo = e.sender;
    var relatedPlaceHolder = "#PlaceHolder_VendorLocationStatusChangesReasonOther_" + vendorLocationID;
    var changedReasonOtherTextBox = "#VendorLocationChangeReasonOther_" + vendorLocationID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedPlaceHolder).removeClass('hidden');
    }
    else {
        $(relatedPlaceHolder).addClass('hidden');
        $(changedReasonOtherTextBox).val('');
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

// Get the Latitude and Longitude for the Given Address
function GetLatitudeLongitude(vendorLocationID) {
    GetAddressDetailsForLatitudeLongitude(vendorLocationID);
}


function GetAddressDetailsForLatitudeLongitude(vendorLocationID) {
    var AddressLine1 = $('#VendorLocationAddressLine1_' + vendorLocationID).val();
    var AddressLine2 = $('#VendorLocationAddressLine2_' + vendorLocationID).val();
    var AddressLine3 = $('#VendorLocationAddressLine3_' + vendorLocationID).val();
    var AddressZipCode = $('#VendorLocationAddressPostalCode_' + vendorLocationID).val();
    var AddressCountryISO = $('#VendorLocationAddressCountryID_' + vendorLocationID).data('kendoComboBox').text();
    var AddressStateAbre = $('#VendorLocationAddressStateProvinceID_' + vendorLocationID).data('kendoComboBox').text();
    var AddressCity = $('#VendorLocationAddressCity_' + vendorLocationID).val();
    var addressData = [];

    addressData.push({ name: "Line1", value: AddressLine1 });
    addressData.push({ name: "Line2", value: AddressLine2 });
    addressData.push({ name: "Line3", value: AddressLine3 });
    addressData.push({ name: "City", value: AddressCity });
    addressData.push({ name: "StateProvince", value: AddressStateAbre });
    addressData.push({ name: "PostalCode", value: AddressZipCode });
    addressData.push({ name: "CountryCode", value: AddressCountryISO });


    // Get the Values
    $.ajax({
        type: 'POST',
        url: '/Common/Addresses/GetLatitudeLongitude',
        traditional: true,
        data: addressData,
        cache: false,
        async: true,
        success: function (msg) {
            if (msg.Status == "Error") {
                openAlertMessage("Unable to locate the latitude and/or longitude for the address.  Please try again.");
            }
            else {
                $('#VendorLocationLatitude_' + vendorLocationID).val(msg.Data.Latitude);
                $('#VendorLocationLongitude_' + vendorLocationID).val(msg.Data.Longitude);
            }
        }
    });
}


// Save and Cancel for Vendor Location Information
function CancelVendorLocationInfSection(vendorID, vendorLocationID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + vendorID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {

            //Hide Validation Message
            $('#frmVendorLocationInfoDetails_' + vendorLocationID).validationEngine("hideAll");
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

    HideErrorIndicator('Error_Indicator_VendorLocation_Info_' + vendorLocationID);

    var FromForVendorLocationInfo = $('#frmVendorLocationInfoDetails_' + vendorLocationID);
    var IsValidForVendorLocationInfo = true;

    // Validation
    if (FromForVendorLocationInfo.validationEngine("validate") == false) {
        IsValidForVendorLocationInfo = false;
    }

    //Validation for Combo Box
    var Combo_Vendor_Location_Status = "VendorLocationStatusID_" + vendorLocationID;
    if (!ValidateCombo(Combo_Vendor_Location_Status)) {
        IsValidForVendorLocationInfo = false;
        return false;
    }

    // Check to See if the User have changed Vendor Location Status then Change Reason id Required
    var Vendor_Location_Status_Old_Value = $('#OldVendorLocationStatusID_' + vendorLocationID).val();
    var Vendor_Location_Status_New_Value = $("#VendorLocationStatusID_" + vendorLocationID).data('kendoComboBox').value();
    var Vendor_Location_Status_New_Text = $("#VendorLocationStatusID_" + vendorLocationID).data('kendoComboBox').text();

    if (Vendor_Location_Status_Old_Value != undefined && Vendor_Location_Status_Old_Value != Vendor_Location_Status_New_Value) {
        var Combo_Vendor_Location_Status_Change_Reson = "VendorLocationChangeReasonID_" + vendorLocationID;
        if (!ValidateCombo(Combo_Vendor_Location_Status_Change_Reson)) {
            IsValidForVendorLocationInfo = false;
        }
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
            if (FromDataForVendorLocationInfo[i].name == "BasicInformation.IsDirectTow_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "BasicInformation.IsDirectTow";
            }

            if (FromDataForVendorLocationInfo[i].name == "IsCoachNetDealerPartner_" + vendorLocationID) {
                FromDataForVendorLocationInfo[i].name = "IsCoachNetDealerPartner";
            }

        }

        FromDataForVendorLocationInfo.push({ name: "BasicInformation.VendorLocationStatusID", value: Vendor_Location_Status_New_Value });
        FromDataForVendorLocationInfo.push({ name: "VendorLocationChangeReasonID", value: $("#VendorLocationChangeReasonID_" + vendorLocationID).data('kendoComboBox').value() });
        FromDataForVendorLocationInfo.push({ name: "AddressInformation.StateProvinceID", value: $("#VendorLocationAddressStateProvinceID_" + vendorLocationID).data('kendoComboBox').value() });
        FromDataForVendorLocationInfo.push({ name: "AddressInformation.CountryID", value: $("#VendorLocationAddressCountryID_" + vendorLocationID).data('kendoComboBox').value() });

        
        //Validation for Address and Other attributes when Vendor Location Staus is Active
        if (Vendor_Location_Status_New_Text == "Active" || Vendor_Location_Status_New_Text == "active") {

            // Validate the Inputs at server side and take the decision
            $.ajax({
                type: 'POST',
                url: '/VendorManagement/VendorHome/_Vendor_Location_Info_Save_Validate',
                data: FromDataForVendorLocationInfo,
                async: false,
                global: false,
                success: function (msg) {
                    if (msg.Status == "Success") {
                        $.ajax({
                            type: 'POST',
                            url: '/VendorManagement/VendorHome/_Vendor_Location_Info_Save',
                            data: FromDataForVendorLocationInfo,
                            success: function (msg) {
                                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                                CleanMyContainer('frmVendorLocationInfoDetails_' + vendorLocationID);
                                CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
                                //Refresh the page 
                                $('#VendorLocationDetails_' + vendorLocationID).tabs('load', 0);
                            }
                        });
                    }
                    else {
                        openAlertMessage(msg.ErrorMessage);
                        //ShowErrorIndicator(msg.ErrorMessage, 'Error_Indicator_VendorLocation_Info_' + vendorLocationID);
                    }
                }
            });

        }
        else {
            $.ajax({
                type: 'POST',
                url: '/VendorManagement/VendorHome/_Vendor_Location_Info_Save',
                data: FromDataForVendorLocationInfo,
                success: function (msg) {
                    
                    // Once the values save to DB Set page to No Dirty and Hide the Buttons
                    CleanMyContainer('frmVendorLocationInfoDetails_' + vendorLocationID);
                    CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
                    //Refresh the page 
                    $('#VendorLocationDetails_' + vendorLocationID).tabs('load', 0);
                }
            });
        }

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

function HandleCoachNetDealerPartnerForVendorLocationInfo(sender, vendorLocationID) {
    if ($(sender).val() == "true") {
        $('#PlaceHolder_For_Vendor_Location_Info_CoachNetDealerPartnerRating_' + vendorLocationID).show();
    }
    else {
        $('#PlaceHolder_For_Vendor_Location_Info_CoachNetDealerPartnerRating_' + vendorLocationID).hide();
    }
}