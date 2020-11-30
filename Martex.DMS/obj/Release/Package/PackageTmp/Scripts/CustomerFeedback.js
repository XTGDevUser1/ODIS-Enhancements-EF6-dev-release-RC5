function tryUnlockAndCloseTab(containerName, customerFeedbackID, tabObject)
{
    $.ajax({
        type: 'POST',
        url: '/CX/CXCustomerFeedback/UnlockRecord',
        data: { recordID: customerFeedbackID },
        traditional: true,
        cache: false,
        async: true,
        success: function (msg) {
            CleanMyContainer(containerName);
            //Refresh the page
            deleteGenericTab(containerName, tabObject);
            if ($('#GrdQACustomerFeedback').data('kendoGrid') != undefined) {
                $('#GrdQACustomerFeedback').data('kendoGrid').dataSource.read();
            }
        }
    });
}
function cancelCustomerFeedbackInformation(customerFeedbackID, tabObjectReference) {
    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var customerFeedbackDirtyContainerName = "frmCustomerFeedbackContainerForDirtyFlag_" + customerFeedbackID;
    if (IsMyContainerDirty(customerFeedbackDirtyContainerName)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            tryUnlockAndCloseTab(customerFeedbackDirtyContainerName, customerFeedbackID, tabObjectReference);
        }, function () {
            return false;
        });
    }
    else {
        tryUnlockAndCloseTab(customerFeedbackDirtyContainerName, customerFeedbackID, tabObjectReference);
    }
}

var winAddCustomerFeedback;
function AddCustomerFeedbackTab(customerFeedBackId, tabObjectReference) {
    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var tabTitle = "In Process";
    if (customerFeedBackId != null && customerFeedBackId > 0) {
        tabTitle = "Customer Feedback -" + customerFeedBackId;
    }
    if (canAddGenericTabInCurrentContainer(tabTitle, tabObjectReference)) {
        $.ajax({
            type: 'POST',
            url: '/CX/CXCustomerFeedback/_Details',
            traditional: true,
            data: { customerFeedBackId: customerFeedBackId },
            cache: false,
            async: true,
            success: function (msg) {
                addGenericTabWithCurrentContainer(tabTitle, tabObjectReference, msg);
            }
        });
    }
}


function openAddCustomerFeedbackActivityCommentWindow(sender, suffixCustomerFeedbackID) {
    if (IsMyContainerDirty("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
            ClearValidationMessages();
            $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).hide();
            $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).show();
        }, function () {
            return false;
        });
    }
    else {
        ClearValidationMessages();
        $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).hide();
        $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).show();
    }
}

function closeAddCustomerFeedbackActivityCommentWindow(sender, suffixCustomerFeedbackID) {
    if (IsMyContainerDirty("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
            $("#CommentType_" + suffixCustomerFeedbackID).data('kendoComboBox').select(0);
            $("#Comments_" + suffixCustomerFeedbackID).val(' ');
            $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).hide();
            ClearValidationMessages();
        }, function () {
            return false;
        });
    }
    else {
        $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).hide();
    }

}


function openAddCustomerFeedbackActivityContactWindow(sender, suffixCustomerFeedbackID) {
    $.ajax({
        type: 'POST',
        url: '/CX/CXCustomerFeedback/_CustomerFeedback_Activity_AddContact',
        traditional: true,
        data: { customerFeedbackId: suffixCustomerFeedbackID },
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (IsMyContainerDirty("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID)) {
                var message = "Changes will not be saved. Do you want to continue and lose the changes?";
                $.modal.confirm(message, function () {
                    CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
                    $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).html(msg);
                    $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).show();
                    $("#CommentType_" + suffixCustomerFeedbackID).data('kendoComboBox').select(0);
                    $("#Comments_" + suffixCustomerFeedbackID).val(' ');
                    $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).hide();
                    ClearValidationMessages();

                }, function () {
                    return false;
                });
            }
            else {
                $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).html(msg);
                $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).show();
                $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).hide();
                ClearValidationMessages();
            }

        }
    });

}

function closeAddCustomerFeedbackActivityContactWindow(sender, suffixCustomerFeedbackID) {
    if (IsMyContainerDirty("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
            ClearValidationMessages();
            $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).hide();

        }, function () {
            return false;
        });
    }
    else {
        $("#divAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).hide();
    }

}


function HandleCustomerFeedbackContactCategoryChange(e, suffixCustomerFeedbackID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    var contactCategoryID = combo.value();
    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixCustomerFeedbackID).data("kendoMultiSelect");
    var contactActionMultiSelect = $("#ContactActionID_" + suffixCustomerFeedbackID).data("kendoMultiSelect");
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

function HandleCustomerFeedbackContactMethodChange(e, suffixCustomerFeedbackID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    ClearValidationMessages();
    var ContactMethodValue = combo.text();
    if (ContactMethodValue == "Phone" || ContactMethodValue == "Text" || ContactMethodValue == "Fax" || ContactMethodValue == "IVR" || ContactMethodValue == "Verbally") {
        $("#divCustomerFeedbackActivityAddContactMethodPhone_" + suffixCustomerFeedbackID).show();
        $("#divCustomerFeedbackActivityAddContactMethodEmail_" + suffixCustomerFeedbackID).hide();
    }
    else if (ContactMethodValue == "Email" || ContactMethodValue == "Mail") {
        $("#divCustomerFeedbackActivityAddContactMethodEmail_" + suffixCustomerFeedbackID).show();
        $("#divCustomerFeedbackActivityAddContactMethodPhone_" + suffixCustomerFeedbackID).hide();
    }
    else {
        $("#divCustomerFeedbackActivityAddContactMethodEmail_" + suffixCustomerFeedbackID).hide();
        $("#divCustomerFeedbackActivityAddContactMethodPhone_" + suffixCustomerFeedbackID).hide();
    }

}


function saveAddCustomerFeedbackActivityComments(sender, suffixCustomerFeedbackID) {
    var errorFound = false;
    if ($("#formAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).validationEngine('validate') == false) {
        errorFound = true;
    }

    var combo = $("#CommentType_" + suffixCustomerFeedbackID).data('kendoComboBox');

    var ComboInput = "CommentType_" + suffixCustomerFeedbackID + "_input";

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

    var Comments = $("#Comments_" + suffixCustomerFeedbackID).val();
    $.ajax({
        type: 'POST',
        url: '/CX/CXCustomerFeedback/SaveCustomerFeedbackActivityComments',
        data: { CommentType: combo.value(), Comments: Comments, customerFeedbackId: suffixCustomerFeedbackID },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
                $("#CommentType_" + suffixCustomerFeedbackID).data('kendoComboBox').select(0);
                $("#Comments_" + suffixCustomerFeedbackID).val(' ');
                openAlertMessage("Comment Added Successfully");
                $("#divAddCustomerFeedbackActivityComment_" + suffixCustomerFeedbackID).hide();
                $("#GrdCustomerFeedbackActivity_" + suffixCustomerFeedbackID).data('kendoGrid').dataSource.read();
            }
        }

    });
    return false;
}

function SaveCustomerFeedbackActivityContact(sender, suffixCustomerFeedbackID) {

    var errorFound = false;
    if ($("#formAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).validationEngine('validate') == false) {
        errorFound = true;
    }
    var contactCategoryCombo = $("#ContactCategory_" + suffixCustomerFeedbackID).data('kendoComboBox');
    var contactCategoryComboInput = "ContactCategory_" + suffixCustomerFeedbackID + "_input";
    if ($.trim(contactCategoryCombo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + contactCategoryComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + contactCategoryComboInput + ']'));
    }

    var combo = $("#ContactMethod_" + suffixCustomerFeedbackID).data('kendoComboBox');

    var ComboInput = "ContactMethod_" + suffixCustomerFeedbackID + "_input";

    if ($.trim(combo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + ComboInput + ']'));
    }

    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixCustomerFeedbackID).data("kendoMultiSelect");
    var contactReasonMultiSelectInput = "#ContactReasonID_" + suffixCustomerFeedbackID + "_taglist";

    if (contactReasonMultiSelect.value().length == 0) {
        HideValidationMessage($(contactReasonMultiSelectInput));
        ShowValidationMessage($(contactReasonMultiSelectInput), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($(contactReasonMultiSelectInput));
    }

    var contactActionMultiSelect = $("#ContactActionID_" + suffixCustomerFeedbackID).data("kendoMultiSelect");
    var contactActionMultiSelectInput = "#ContactActionID_" + suffixCustomerFeedbackID + "_taglist";

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
    var formData = $("#formAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).serializeArray();
    //Email = null
    formData.push({ name: "ContactMethod", value: combo.value() });
    formData.push({ name: "ContactMethodValue", value: combo.text() });

    formData.push({ name: "ContactCategory", value: contactCategoryCombo.value() });
    formData.push({ name: "ContactCategoryValue", value: contactCategoryCombo.text() });

    formData.push({ name: "Email", value: $("#Email_" + suffixCustomerFeedbackID).val() });
    formData.push({ name: "TalkedTo", value: $("#TalkedTo_" + suffixCustomerFeedbackID).val() });
    formData.push({ name: "Notes", value: $("#Notes_" + suffixCustomerFeedbackID).val() });
    formData.push({ name: "PhoneNumber", value: GetPhoneNumberForDB("PhoneNumber_" + suffixCustomerFeedbackID) });

    var phoneNumberTypeID = $("#PhoneNumber_" + suffixCustomerFeedbackID + "_ddlPhoneType").val();
    formData.push({ name: "PhoneNumberType", value: phoneNumberTypeID });

    formData.push({ name: "CustomerFeedbackID", value: suffixCustomerFeedbackID });
    $.ajax({
        type: 'POST',
        url: '/CX/CXCustomerFeedback/SaveCustomerFeedbackActivityContact',
        data: formData,
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmCustomerFeedbackContainerForDirtyFlag_" + suffixCustomerFeedbackID);
                openAlertMessage("Contact Added Successfully");
                $("#formAddCustomerFeedbackActivityContact_" + suffixCustomerFeedbackID).hide();
                $("#GrdCustomerFeedbackActivity_" + suffixCustomerFeedbackID).data('kendoGrid').dataSource.read();
            }

        }

    });
    return false;

}