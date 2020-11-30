var WARRANTY = "Motorhome Reimbursement";
var ROADSIDE = "Roadside Reimbursement";
var DAMAGE = "Damage Reimbursement";
var FORD_QFC = "Ford QFC";

var PAYEE_MEMEBR = "Member";
var PAYEE_VENDOR = "Vendor";

/* Moved Functions here */
/* Claim Information is being consumed from multiple places*/


function AddClaimTab(claimID, tabObjectReference) {
    
    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var tabTitle = "In Process";
    if (claimID != null && claimID > 0) {
        tabTitle = "Claim-" + claimID;
    }
    if (canAddGenericTabInCurrentContainer(tabTitle, tabObjectReference)) {
        $.ajax({
            type: 'POST',
            url: '/Claims/Claim/_ClaimDetails',
            traditional: true,
            data: { claimID: claimID },
            cache: false,
            async: true,
            success: function (msg) {
                addGenericTabWithCurrentContainer(tabTitle, tabObjectReference, msg);
            }
        });
    }
}

function CancelClaimInformation(claimID, tabObjectReference) {
    
    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var claimDirtyContainerName = "frmClaimContainerForDirtyFlag_" + claimID;
    if (IsMyContainerDirty(claimDirtyContainerName)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            CleanMyContainer(claimDirtyContainerName);
            //Refresh the page 
            deleteGenericTab(claimDirtyContainerName, tabObjectReference);
            AddClaimTab(claimID, tabObjectReference);

        }, function () {
            return false;
        });
    }
    else {
        //Refresh the page 
        deleteGenericTab(claimDirtyContainerName, tabObjectReference);
        AddClaimTab(claimID, tabObjectReference);
    }
}

function SaveClaimInformation(claimID,tabObjectReference) {

    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var isClaimInformationIsValid = true;
    var claimDirtyContainerName = "frmClaimContainerForDirtyFlag_" + claimID;
    
    if ($('#frmCLaimInformation_' + claimID).validationEngine("validate") == false) {
        isClaimInformationIsValid = false;
    }

    if ($('#frmPayeeInformation_' + claimID).validationEngine("validate") == false) {
        isClaimInformationIsValid = false;
    }
    if ($('#frmClaimVehicles_' + claimID).validationEngine("validate") == false) {
        isClaimInformationIsValid = false;
    }

    if (isClaimInformationIsValid) {

        var postData = $('#frmCLaimInformation_' + claimID).serializeArray();
        postData.push({ name: "Claim.ClaimStatusID", value: GetComboValue("ClaimStatusID_" + claimID) });
        postData.push({ name: "Claim.ClaimRejectReasonID", value: GetComboValue("ClaimRejectReason_" + claimID) });
        postData.push({ name: "Claim.ClaimCategoryID", value: GetComboValue("ClaimCategoryID_" + claimID) });
        postData.push({ name: "Claim.ReceiveContactMethodID", value: GetComboValue("ReceiveContactMethodID_" + claimID) });
        postData.push({ name: "Claim.NextActionID", value: GetComboValue("NextActionID_" + claimID) });
        postData.push({ name: "Claim.NextActionAssignedToUserID", value: GetComboValue("NextActionAssignedToUserID_" + claimID) });
        if ($("#ACESClaimStatus_" + claimID).length > 0 && $("#ACESClaimStatus_" + claimID).data) {
            postData.push({ name: "Claim.ACESClaimStatusID", value: GetComboValue("ACESClaimStatus_" + claimID) });
        }

        // For Payee Tab
        postData.push({ name: "Claim.PayeeType", value: GetComboValue("ClaimPayeeType_" + claimID) });
        postData.push({ name: "Claim.PaymentAddressStateProvinceID", value: GetComboValue("PaymentAddressStateProvinceID_" + claimID) });
        postData.push({ name: "Claim.PaymentAddressCountryID", value: GetComboValue("PaymentAddressCountryID_" + claimID) });
        postData.push({ name: "Claim.ContactPhoneNumber", value: GetPhoneNumberForDB('PayeePhoneNumber_' + claimID) });
        postData.push({ name: "ClaimStatusName", value: $('#ClaimStatusID_' + claimID).data('kendoComboBox').text() });
        postData.push({ name: "ProgramName", value: $('#ProgramName_' + claimID).val() });


        //Get the data from Payee Tab
        var payeeTabData = $('#frmPayeeInformation_' + claimID).serializeArray();
        //Get the data from Vehcile Tab
        var vehicleTabData = $('#frmClaimVehicles_' + claimID).serializeArray();
        var serviceData = $("#frmClaimServices_" + claimID).serializeArray();

        postData = $.merge(postData, payeeTabData);
        postData = $.merge(postData, vehicleTabData);
        postData = $.merge(postData, serviceData);

        $.ajax({
            url: '/Claims/Claim/SaveClaimInformation',
            type: 'POST',
            data: postData,
            success: function (msg) {
                if (msg.Status = "Success") {
                    CleanMyContainer("frmClaimContainerForDirtyFlag_" + claimID);
                    if (msg.Data.Mode == "Edit") {
                        deleteGenericTab(claimDirtyContainerName, tabObjectReference);
                        AddClaimTab(msg.Data.ClaimID, tabObjectReference);
                    }
                    else {
                        deleteGenericTab(claimDirtyContainerName, tabObjectReference);
                        AddClaimTab(msg.Data.ClaimID, tabObjectReference);
                    }
                    if ($('#GrdClaims').data('kendoGrid') != undefined) {
                        $('#GrdClaims').data('kendoGrid').dataSource.read();
                    }
                }
            }
        })
    }

    return false;
}

function HandleContactMethodChange(e, suffixClaimID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    ClearValidationMessages();
    var ContactMethodValue = combo.text();
    if (ContactMethodValue == "Phone" || ContactMethodValue == "Text" || ContactMethodValue == "Fax" || ContactMethodValue == "IVR" || ContactMethodValue == "Verbally") {
        $("#divClaimActivityAddContactMethodPhone_" + suffixClaimID).show();
        $("#divClaimActivityAddContactMethodEmail_" + suffixClaimID).hide();
    }
    else if (ContactMethodValue == "Email" || ContactMethodValue == "Mail") {
        $("#divClaimActivityAddContactMethodEmail_" + suffixClaimID).show();
        $("#divClaimActivityAddContactMethodPhone_" + suffixClaimID).hide();
    }
    else {
        $("#divClaimActivityAddContactMethodEmail_" + suffixClaimID).hide();
        $("#divClaimActivityAddContactMethodPhone_" + suffixClaimID).hide();
    }

}

function GetComboValue(comboID) {
    return $('#' + comboID).data('kendoComboBox').value();
}

function HandleClaimInformationStatus(e, claimID) {

    var combo = e.sender;

    var relatedClaimReasonPlaceHolder = "#PlaceHolder_ClaimReason_" + claimID;
    var relatedRejectCombo = $("#ClaimRejectReason_" + claimID).data('kendoComboBox');

    var relatedClaimReasonOtherPlaceHolder = "#PlaceHolder_ClaimReasonOther_" + claimID;
    var relatedClaimReasonOtherTextBox = "#ClaimRejectReasonOther_" + claimID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    if ($.trim(combo.text()).length > 0 && combo.text() == "Denied") {
        $(relatedClaimReasonPlaceHolder).show();
    }
    else {
        relatedRejectCombo.value('');
        $(relatedClaimReasonOtherTextBox).val('');
        $(relatedClaimReasonPlaceHolder).hide();
        $(relatedClaimReasonOtherPlaceHolder).hide();
    }
}

function HandleClaimRejectReasonOther(e, claimID) {
    var combo = e.sender;
    var relatedClaimReasonOtherPlaceHolder = "#PlaceHolder_ClaimReasonOther_" + claimID;
    var relatedClaimReasonOtherTextBox = "#ClaimRejectReasonOther_" + claimID;

    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }

    if ($.trim(combo.text()).length > 0 && combo.text() == "Other") {
        $(relatedClaimReasonOtherPlaceHolder).show();
    }
    else {
        $(relatedClaimReasonOtherPlaceHolder).hide();
        $(relatedClaimReasonOtherTextBox).val('');
    }
}

function openAddClaimActivityCommentWindow(sender, suffixClaimID) {
    if (IsMyContainerDirty("frmClaimContainerForDirtyFlag_" + suffixClaimID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
            ClearValidationMessages();
            $("#divAddClaimActivityContact_" + suffixClaimID).hide();
            $("#divAddClaimActivityComment_" + suffixClaimID).show();
        }, function () {
            return false;
        });
    }
    else {
        ClearValidationMessages();
        $("#divAddClaimActivityContact_" + suffixClaimID).hide();
        $("#divAddClaimActivityComment_" + suffixClaimID).show();
    }
}

function closeAddClaimActivityCommentWindow(sender, suffixClaimID) {
    if (IsMyContainerDirty("frmClaimContainerForDirtyFlag_" + suffixClaimID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
            $("#CommentType_" + suffixClaimID).data('kendoComboBox').select(0);
            $("#Comments_" + suffixClaimID).val(' ');
            $("#divAddClaimActivityComment_" + suffixClaimID).hide();
            ClearValidationMessages();
        }, function () {
            return false;
        });
    }
    else {
        $("#divAddClaimActivityComment_" + suffixClaimID).hide();
    }

}

function saveAddClaimActivityComments(sender, suffixClaimID) {

    var errorFound = false;
    if ($("#formAddClaimActivityComment_" + suffixClaimID).validationEngine('validate') == false) {
        errorFound = true;
    }

    var combo = $("#CommentType_" + suffixClaimID).data('kendoComboBox');

    var ComboInput = "CommentType_" + suffixClaimID + "_input";

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

    var Comments = $("#Comments_" + suffixClaimID).val();
    $.ajax({
        type: 'POST',
        url: '/Claims/Claim/SaveClaimActivityComments',
        data: { CommentType: combo.value(), Comments: Comments, ClaimID: suffixClaimID },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
                $("#CommentType_" + suffixClaimID).data('kendoComboBox').select(0);
                $("#Comments_" + suffixClaimID).val(' ');
                openAlertMessage("Comment Added Successfully");
                $("#divAddClaimActivityComment_" + suffixClaimID).hide();
                $("#GrdClaimActivity_" + suffixClaimID).data('kendoGrid').dataSource.read();
            }
        }

    });
    return false;
}

function openAddClaimActivityContactWindow(sender, suffixClaimID) {
    $.ajax({
        type: 'POST',
        url: '/Claims/Claim/_Claim_Activity_AddContact',
        traditional: true,
        data: { ClaimID: suffixClaimID },
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (IsMyContainerDirty("frmClaimContainerForDirtyFlag_" + suffixClaimID)) {
                var message = "Changes will not be saved. Do you want to continue and lose the changes?";
                $.modal.confirm(message, function () {
                    CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
                    $("#divAddClaimActivityContact_" + suffixClaimID).html(msg);
                    $("#divAddClaimActivityContact_" + suffixClaimID).show();
                    $("#CommentType_" + suffixClaimID).data('kendoComboBox').select(0);
                    $("#Comments_" + suffixClaimID).val(' ');
                    $("#divAddClaimActivityComment_" + suffixClaimID).hide();
                    ClearValidationMessages();

                }, function () {
                    return false;
                });
            }
            else {
                $("#divAddClaimActivityContact_" + suffixClaimID).html(msg);
                $("#divAddClaimActivityContact_" + suffixClaimID).show();
                $("#divAddClaimActivityComment_" + suffixClaimID).hide();
                ClearValidationMessages();
            }

        }
    });

}

function HandleClaimContactCategoryChange(e, suffixClaimID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    var contactCategoryID = combo.value();
    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixClaimID).data("kendoMultiSelect");
    var contactActionMultiSelect = $("#ContactActionID_" + suffixClaimID).data("kendoMultiSelect");
    contactReasonMultiSelect.value('');
    contactActionMultiSelect.value('');
    if (contactCategoryID != null && contactCategoryID != undefined && contactCategoryID > 0) {
        $.ajax({
            type: 'POST',
            url: '/MemberManagement/Member/GetContactActionsAndReasonsForCategory',
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
                    var ComboInput = "ContactCategory_" + suffixMemberID + "_input";
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
function closeAddClaimActivityContactWindow(sender, suffixClaimID) {
    if (IsMyContainerDirty("frmClaimContainerForDirtyFlag_" + suffixClaimID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
            ClearValidationMessages();
            $("#divAddClaimActivityContact_" + suffixClaimID).hide();

        }, function () {
            return false;
        });
    }
    else {
        $("#divAddClaimActivityContact_" + suffixClaimID).hide();
    }

}

function saveAddClaimActivityContact(sender, suffixClaimID) {

    var errorFound = false;
    if ($("#formAddClaimActivityContact_" + suffixClaimID).validationEngine('validate') == false) {
        errorFound = true;
    }
    var contactCategoryCombo = $("#ContactCategory_" + suffixClaimID).data('kendoComboBox');
    var contactCategoryComboInput = "ContactCategory_" + suffixClaimID + "_input";
    if ($.trim(contactCategoryCombo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + contactCategoryComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + contactCategoryComboInput + ']'));
    }

    var combo = $("#ContactMethod_" + suffixClaimID).data('kendoComboBox');

    var ComboInput = "ContactMethod_" + suffixClaimID + "_input";

    if ($.trim(combo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + ComboInput + ']'));
    }

    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixClaimID).data("kendoMultiSelect");
    var contactReasonMultiSelectInput = "#ContactReasonID_" + suffixClaimID + "_taglist";

    if (contactReasonMultiSelect.value().length == 0) {
        HideValidationMessage($(contactReasonMultiSelectInput));
        ShowValidationMessage($(contactReasonMultiSelectInput), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($(contactReasonMultiSelectInput));
    }

    var contactActionMultiSelect = $("#ContactActionID_" + suffixClaimID).data("kendoMultiSelect");
    var contactActionMultiSelectInput = "#ContactActionID_" + suffixClaimID + "_taglist";

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
    var formData = $("#formAddClaimActivityContact_" + suffixClaimID).serializeArray();
    //Email = null
    formData.push({ name: "ContactMethod", value: combo.value() });
    formData.push({ name: "ContactMethodValue", value: combo.text() });

    formData.push({ name: "ContactCategory", value: contactCategoryCombo.value() });
    formData.push({ name: "ContactCategoryValue", value: contactCategoryCombo.text() });

    formData.push({ name: "Email", value: $("#Email_" + suffixClaimID).val() });
    formData.push({ name: "TalkedTo", value: $("#TalkedTo_" + suffixClaimID).val() });
    formData.push({ name: "Notes", value: $("#Notes_" + suffixClaimID).val() });
    formData.push({ name: "PhoneNumber", value: GetPhoneNumberForDB("PhoneNumber_" + suffixClaimID) });

    var phoneNumberTypeID = $("#PhoneNumber_" + suffixClaimID + "_ddlPhoneType").val();
    formData.push({ name: "PhoneNumberType", value: phoneNumberTypeID });

    formData.push({ name: "ClaimID", value: suffixClaimID });
    $.ajax({
        type: 'POST',
        url: '/Claims/Claim/SaveClaimActivityContact',
        data: formData,
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmClaimContainerForDirtyFlag_" + suffixClaimID);
                openAlertMessage("Contact Added Successfully");
                $("#divAddClaimActivityContact_" + suffixClaimID).hide();
                $("#GrdClaimActivity_" + suffixClaimID).data('kendoGrid').dataSource.read();
            }

        }

    });
    return false;

}


/*ends here */

function LookUpForMemberAddressAndPhoneNumber(e, claimID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
    }
    var comboValue = combo.value();
    if (comboValue != undefined && comboValue != '' && comboValue > 0) {
        $.ajax({
            type: 'GET',
            url: '/Claims/Claim/_MemberAddressAndPhoneNumber',
            traditional: true,
            data: { memberID: comboValue },
            cache: false,
            async: true,
            success: function (msg) {
                if (msg.Status == "Success") {
                    SetAddressDetails(msg.Data.Details, claimID)
                    SetPhoneNumber(msg.Data.Details, claimID);
                }
            }
        });
    }
    else {
        ResetAddressDetails(claimID);
        ResetPhoneDetails(claimID);
    }
}

function SetAddressDetails(addressDetails, claimID) {
    var payeeContactName = $('#PayeeContactName_' + claimID);
    var addressline1 = $('#PayeePaymentAddressLine1_' + claimID);
    var addressline2 = $('#PayeePaymentAddressLine2_' + claimID);
    var addressline3 = $('#PayeePaymentAddressLine3_' + claimID);
    var addressCity = $('#PayeePaymentAddressCity_' + claimID);
    var addressPostalCode = $('#PaymentAddressPostalCode_' + claimID);
    var addressCountry = $('#PaymentAddressCountryID_' + claimID).data('kendoComboBox');
    var addressState = $('#PaymentAddressStateProvinceID_' + claimID).data('kendoComboBox');
    if (addressDetails.IsAddressFound == "true" || addressDetails.IsAddressFound == true) {
        addressline1.val(addressDetails.Line1);
        addressline2.val(addressDetails.Line2);
        addressline3.val(addressDetails.Line3);
        addressCity.val(addressDetails.City);
        addressPostalCode.val(addressDetails.PostalCode);
        addressCountry.value(addressDetails.CountryID);
        payeeContactName.val(addressDetails.MemberName);
        CascadeStateFromCountryAndSetValue(claimID, addressDetails.StateProvinceID);
    }
    else {
        ResetAddressDetails(claimID);
    }
}

function ResetPhoneDetails(claimID) {
    SetPhoneValues("PayeePhoneNumber_" + claimID, '');
}

function ResetAddressDetails(claimID) {
    var payeeContactName = $('#PayeeContactName_' + claimID);
    var addressline1 = $('#PayeePaymentAddressLine1_' + claimID);
    var addressline2 = $('#PayeePaymentAddressLine2_' + claimID);
    var addressline3 = $('#PayeePaymentAddressLine3_' + claimID);
    var addressCity = $('#PayeePaymentAddressCity_' + claimID);
    var addressPostalCode = $('#PaymentAddressPostalCode_' + claimID);
    var addressCountry = $('#PaymentAddressCountryID_' + claimID).data('kendoComboBox');
    var addressState = $('#PaymentAddressStateProvinceID_' + claimID).data('kendoComboBox');
    addressline1.val('');
    addressline2.val('');
    addressline3.val('');
    addressCity.val('');
    addressPostalCode.val('');
    addressCountry.value('');
    addressState.value('');
    payeeContactName.val('');
}
function SetPhoneNumber(phoneDetails, claimID) {
    if (phoneDetails.IsPhoneFound == "true" || phoneDetails.IsPhoneFound == true) {
        SetPhoneValues("PayeePhoneNumber_" + claimID, phoneDetails.MemberPhoneNumber);
    }
    else {
        ResetPhoneDetails(claimID);
    }
}

function CascadeStateFromCountryAndSetValue(claimID, stateID) {
    var combo = $('#PaymentAddressCountryID_' + claimID).data('kendoComboBox'); ;
    var vehicleState = $('#PaymentAddressStateProvinceID_' + claimID).data('kendoComboBox');
    $.ajax({
        type: 'GET',
        url: '/Common/ReferenceData/GetStateProvinceWithID',
        traditional: true,
        data: { countryID: combo.value() },
        cache: false,
        async: true,
        success: function (msg) {
            vehicleState.setDataSource(msg);
            vehicleState.value(stateID);
        }
    });
}

function LoadVehicleInformaiton(programID, claimID, membershipNumber) {
    $.ajax({
        url: '/Claims/Claim/_Claims_Vehicle_Service',
        data: { claimID: claimID, programID: programID, membershipNumber: membershipNumber },
        success: function (msg) {
            $('#ClaimsVehicleServiceTab_' + claimID).html(msg);
        }
    });
}

function EnableTabsBasedonTheClaimType(claimTypeName, claimID) {

    var disableTabListForFordQFC = [1, 2, 3, 5];
    var disableTabListForDamage = [2, 3]; // Vehcile is Disabled When it;s a PO
    var disableTabListForRoadside = [4]; // Road Side PO IS Disabled
    var disableTabListForWarranty = [4]; // Warranty Side PO IS Disabled

    $('#ClaimsDocumentTab_' + claimID).removeClass("disabled");

    if (claimTypeName == FORD_QFC) {
        $('#TABClaimsInfoTab_' + claimID).removeClass("disabled");
        $('#ClaimsPOTab_' + claimID).removeClass("disabled");
        return disableTabListForFordQFC;
    }
    else if (claimTypeName == DAMAGE) {
        $('#TABClaimsInfoTab_' + claimID).removeClass("disabled");
        $('#TABClaimsPayeeTab_' + claimID).removeClass("disabled");
        $('#ClaimsPOTab_' + claimID).removeClass("disabled");
        $('#ClaimsActivityTab_' + claimID).removeClass("disabled");
        return disableTabListForDamage;
    }
    else if (claimTypeName == WARRANTY) {
        $('#TABClaimsInfoTab_' + claimID).removeClass("disabled");
        $('#TABClaimsPayeeTab_' + claimID).removeClass("disabled");
        $('#TABClaimsVehicleServiceTab_' + claimID).removeClass("disabled");
        $('#TABClaimsServiceTab_' + claimID).removeClass("disabled");
        $('#ClaimsActivityTab_' + claimID).removeClass("disabled");
        return disableTabListForWarranty;
    }
    else if (claimTypeName == ROADSIDE) {
        $('#TABClaimsInfoTab_' + claimID).removeClass("disabled");
        $('#TABClaimsPayeeTab_' + claimID).removeClass("disabled");
        $('#TABClaimsVehicleServiceTab_' + claimID).removeClass("disabled");
        $('#TABClaimsServiceTab_' + claimID).removeClass("disabled");
        $('#ClaimsActivityTab_' + claimID).removeClass("disabled");
        return disableTabListForRoadside;

    }
}

function EnableClaimInformationFields() {
    $('#frmCLaimInformation_0 :input').each(function () {
        try {
            var roleName = $(this).attr('dmsrole');
            var elementID = $(this).attr('id');
            if (roleName != undefined && elementID != undefined) {
                if (roleName == "Combo") {
                    $('#' + elementID).data('kendoComboBox').enable();
                }
                if (roleName == "DatePicker") {
                    $('#' + elementID).data('kendoDatePicker').enable();
                }
                if (roleName == "DateTimePicker") {
                    $('#' + elementID).data('kendoDateTimePicker').enable();
                }
                if (roleName == "numericTextBox") {
                    $('#' + elementID).data('kendoNumericTextBox').enable();
                }
                if (roleName == "text") {
                    $('#' + elementID).removeAttr("disabled");
                }
                if (roleName == "chkBox") {
                    $('#' + elementID).removeAttr("disabled");
                    $('#' + elementID).parent().removeClass('disabled');
                }
            }

        } catch (e) {

        }

    });
}

function AdjustPayeeTypeFields(claimID, payeeType) {

    var placeHolderForMemberPayee = $("#PlaceHolder_Payee_Type_Member_" + claimID);
    var placeHolderForVendorPayee = $("#PlaceHolder_Payee_Type_Vendor_" + claimID);

    if (payeeType == PAYEE_MEMEBR) {
        placeHolderForMemberPayee.show();
        placeHolderForVendorPayee.hide();
    }
    else if (payeeType == PAYEE_VENDOR) {
        placeHolderForVendorPayee.show();
        placeHolderForMemberPayee.hide();
    }
}

/* Cascading Drop Downs */
function LicenseStateCountryChangeClaimPayee(e, claimID) {
    var combo = e.sender;
    var vehicleState = $('#PaymentAddressStateProvinceID_' + claimID).data('kendoComboBox');
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        ResetCombo(vehicleState);

    }
    
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
            var elementState = "input[name='PaymentAddressStateProvinceID_" + claimID + "_input']";
            $(elementState).focus();
            $(elementState).select();

        }
    });
}

function CascadingMemberForMembershipNumber(claimID) {

    var membershipCombo = $('#MemberID_' + claimID).data('kendoComboBox');
    var membershipNumber = $('#MembershipNumber_' + claimID).val();
    $.ajax({
        type: 'GET',
        url: '/Common/ReferenceData/GetMemberByMembershipNumber',
        traditional: true,
        data: { membershipNumber: membershipNumber },
        cache: false,
        async: true,
        success: function (msg) {
            membershipCombo.setDataSource(msg);
            membershipCombo.select(0);
            var elementState = "input[name='MemberID_" + claimID + "_input']";
            $(elementState).focus();
            $(elementState).select();

        }
    });
}

function CascadingMemberForMembershipNumberWithSet(claimID, memberID) {

    var membershipCombo = $('#MemberID_' + claimID).data('kendoComboBox');
    var membershipNumber = $('#MembershipNumber_' + claimID).val();
    $.ajax({
        type: 'GET',
        url: '/Common/ReferenceData/GetMemberByMembershipNumber',
        traditional: true,
        data: { membershipNumber: membershipNumber },
        cache: false,
        async: true,
        success: function (msg) {
            membershipCombo.setDataSource(msg);
            $('#MemberID_' + claimID).data('kendoComboBox').value(memberID);
        }
    });
}

