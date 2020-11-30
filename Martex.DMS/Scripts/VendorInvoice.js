
function fnPanelCollapseR(e) {
    $(e.item).find("> .k-link").removeClass("k-state-selected");
    $(e.item).find("> .k-link").removeClass("k-state-focused");
    var panelName = $(e.item).find("> .k-link").attr("id");
    panelName = panelName.replace("Panel_", "");
    $('#' + panelName).val('false');
}

function fnPanelExpandR(e) {
    $(e.item).find("> .k-link").addClass("k-state-selected");
    $(e.item).find("> .k-link").addClass("k-state-focused");
    var panelName = $(e.item).find("> .k-link").attr("id");
    panelName = panelName.replace("Panel_", "");
    $('#' + panelName).val('true');
}

function DeleteVendorInvoice(vendorInvoiceID) {
    $.modal.confirm("Are you sure you want to delete this invoice?", function () {
        $.ajax({
            type: 'GET',
            url: '/VendorManagement/VendorInvoices/_DeleteVendorInvoice',
            traditional: true,
            data: { vendorInvoiceID: vendorInvoiceID },
            cache: false,
            async: true,
            success: function (msg) {
                if (msg.Status = "Success") {
                    openAlertMessage("Vendor Invoice Deleted Successfully");
                    $("#GrdVendorInvoices").data('kendoGrid').dataSource.read();
                }
            }
        });

    }, function () {
        return false;
    });
}

function openAddVendorInvoiceActivityCommentWindow(sender, suffixVendorInvoiceID) {
    if (IsMyContainerDirty("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
            $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).hide();
            $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).show();
            ClearValidationMessages();
        }, function () {
            return false;
        });
    }
    else {
        $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).hide();
        $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).show();
        ClearValidationMessages();
    }
}

function closeAddVendorInvoiceActivityCommentWindow(sender, suffixVendorInvoiceID) {
    if (IsMyContainerDirty("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            $("#CommentType_" + suffixVendorInvoiceID).data('kendoComboBox').select(0);
            $("#Comments_" + suffixVendorInvoiceID).val(' ');
            $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).hide();
            CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
            ClearValidationMessages();
        }, function () {
            return false;
        });
    }
    else {
        $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).hide();
        ClearValidationMessages();
    }

}

function saveAddVendorInvoiceActivityComments(sender, suffixVendorInvoiceID) {

    var errorFound = false;
    if ($("#formAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).validationEngine('validate') == false) {
        errorFound = true;
    }

    var combo = $("#CommentType_" + suffixVendorInvoiceID).data('kendoComboBox');

    var ComboInput = "CommentType_" + suffixVendorInvoiceID + "_input";

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

    var Comments = $("#Comments_" + suffixVendorInvoiceID).val();
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/SaveVendorInvoiceActivityComments',
        data: { CommentType: combo.value(), Comments: Comments, VendorInvoiceID: suffixVendorInvoiceID },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                $("#CommentType_" + suffixVendorInvoiceID).data('kendoComboBox').select(0);
                $("#Comments_" + suffixVendorInvoiceID).val(' ');
                openAlertMessage("Comment Added Successfully");
                $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).hide();
                $("#GrdVendorInvoiceActivity_" + suffixVendorInvoiceID).data('kendoGrid').dataSource.read();
            }
        }

    });
    return false;
}

function openAddVendorInvoiceActivityContactWindow(sender, suffixVendorInvoiceID, suffixVendorID) {
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/_Vendor_Invoices_Activity_AddContact',
        traditional: true,
        data: { vendorInvoiceID: suffixVendorInvoiceID, vendorID: suffixVendorID },
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (IsMyContainerDirty("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID)) {
                var message = "Changes will not be saved. Do you want to continue and lose the changes?";
                $.modal.confirm(message, function () {
                    CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                    $("#CommentType_" + suffixVendorInvoiceID).data('kendoComboBox').select(0);
                    $("#Comments_" + suffixVendorInvoiceID).val(' ');
                    $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).html(msg);
                    $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).show();
                    $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).hide();
                    ClearValidationMessages();

                }, function () {
                    return false;
                });
            }
            else {
                ClearValidationMessages();
                $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).html(msg);
                $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).show();
                $("#divAddVendorInvoiceActivityComment_" + suffixVendorInvoiceID).hide();
            }

        }
    });

}

function HandleContactMethodChange(e, suffixVendorInvoiceID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    ClearValidationMessages();
    var ContactMethodValue = combo.text();
    if (ContactMethodValue == "Phone" || ContactMethodValue == "Text" || ContactMethodValue == "Fax" || ContactMethodValue == "IVR" || ContactMethodValue == "Verbally") {
        $("#divVendorInvoiceActivityAddContactMethodPhone_" + suffixVendorInvoiceID).show();
        $("#divVendorInvoiceActivityAddContactMethodEmail_" + suffixVendorInvoiceID).hide();
    }
    else if (ContactMethodValue == "Email" || ContactMethodValue == "Mail") {
        $("#divVendorInvoiceActivityAddContactMethodEmail_" + suffixVendorInvoiceID).show();
        $("#divVendorInvoiceActivityAddContactMethodPhone_" + suffixVendorInvoiceID).hide();
    }
    else {
        $("#divVendorInvoiceActivityAddContactMethodEmail_" + suffixVendorInvoiceID).hide();
        $("#divVendorInvoiceActivityAddContactMethodPhone_" + suffixVendorInvoiceID).hide();
    }

}

function HandleVendorInvoiceContactCategoryChange(e, suffixVendorInvoiceID, suffixVendorID) {
    var combo = e.sender;
    if (!IsUserInputValidForChangeOnKendoCombo(combo)) {
        e.preventDefault();
        return false;
    }
    var contactCategoryID = combo.value();
    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixVendorInvoiceID).data("kendoMultiSelect");
    var contactActionMultiSelect = $("#ContactActionID_" + suffixVendorInvoiceID).data("kendoMultiSelect");
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

function closeAddVendorInvoiceActivityContactWindow(sender, suffixVendorInvoiceID) {
    if (IsMyContainerDirty("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
            $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).hide();

        }, function () {
            return false;
        });
    }
    else {
        $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).hide();
    }

}

function saveAddVendorInvoiceActivityContact(sender, suffixVendorInvoiceID, suffixVendorID) {

    var errorFound = false;
    if ($("#formAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).validationEngine('validate') == false) {
        errorFound = true;
    }

    var contactCategoryCombo = $("#ContactCategory_" + suffixVendorInvoiceID).data('kendoComboBox');
    var contactCategoryComboInput = "ContactCategory_" + suffixVendorInvoiceID + "_input";
    if ($.trim(contactCategoryCombo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + contactCategoryComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + contactCategoryComboInput + ']'));
    }

    var combo = $("#ContactMethod_" + suffixVendorInvoiceID).data('kendoComboBox');

    var ComboInput = "ContactMethod_" + suffixVendorInvoiceID + "_input";

    if ($.trim(combo.value()).length == 0) {
        ShowValidationMessage($('input[name=' + ComboInput + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[name=' + ComboInput + ']'));
    }

    var contactReasonMultiSelect = $("#ContactReasonID_" + suffixVendorInvoiceID).data("kendoMultiSelect");
    var contactReasonMultiSelectInput = "#ContactReasonID_" + suffixVendorInvoiceID + "_taglist";

    if (contactReasonMultiSelect.value().length == 0) {
        HideValidationMessage($(contactReasonMultiSelectInput));
        ShowValidationMessage($(contactReasonMultiSelectInput), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($(contactReasonMultiSelectInput));
    }

    var contactActionMultiSelect = $("#ContactActionID_" + suffixVendorInvoiceID).data("kendoMultiSelect");
    var contactActionMultiSelectInput = "#ContactActionID_" + suffixVendorInvoiceID + "_taglist";

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
    var formData = $("#formAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).serializeArray();
    //Email = null
    formData.push({ name: "ContactMethod", value: combo.value() });
    formData.push({ name: "ContactMethodValue", value: combo.text() });

    formData.push({ name: "ContactCategory", value: contactCategoryCombo.value() });
    formData.push({ name: "ContactCategoryValue", value: contactCategoryCombo.text() });

    formData.push({ name: "Email", value: $("#Email_" + suffixVendorInvoiceID).val() });
    formData.push({ name: "TalkedTo", value: $("#TalkedTo_" + suffixVendorInvoiceID).val() });
    formData.push({ name: "Notes", value: $("#Notes_" + suffixVendorInvoiceID).val() });
    formData.push({ name: "PhoneNumber", value: GetPhoneNumberForDB("PhoneNumber_" + suffixVendorInvoiceID) });

    var phoneNumberTypeID = $("#PhoneNumber_" + suffixVendorInvoiceID + "_ddlPhoneType").val();
    formData.push({ name: "PhoneNumberType", value: phoneNumberTypeID });

    formData.push({ name: "VendorInvoiceID", value: suffixVendorInvoiceID });

    formData.push({ name: "VendorID", value: suffixVendorID });
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/SaveVendorInvoiceActivityContact',
        data: formData,
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "Success") {
                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                openAlertMessage("Contact Added Successfully");
                $("#divAddVendorInvoiceActivityContact_" + suffixVendorInvoiceID).hide();
                $("#GrdVendorInvoiceActivity_" + suffixVendorInvoiceID).data('kendoGrid').dataSource.read();
            }
        }
    });
    return false;
}

function verifyPONumber(sender, suffixVendorInvoiceID) {
    var formElemnt = $("#frmPoNumberVerfiy_" + suffixVendorInvoiceID);
    var poNumber = $("#PONumber_" + suffixVendorInvoiceID).val();
    if (poNumber.length == 0) {
        ClearValidationMessages();
        ShowStatus("error", "Please enter a PO number.", formElemnt);
        return false;
    }
    //success
    ShowStatus("inprogress", "Verifying purchase order...", formElemnt);
    $("#divPODetails_" + suffixVendorInvoiceID).html('');
    $("#divVendorDetails_" + suffixVendorInvoiceID).html('');
    $("#divProcessingDetails_" + suffixVendorInvoiceID).html('');
    var vendorInvoiceIDofPO = 0;
    var poID = 0;
    var vendorLocationID = 0;
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/CheckIfPOExistsOrNot',
        data: { PONumber: poNumber },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            if (msg.Status == "PONotFound") {
                ShowStatus("error", "PO number was not found please try again.", formElemnt);
            }
            else if (msg.Status == "PODeleted") {
                ShowStatus("error", "PO was deleted", formElemnt);
            }
            else if (msg.Status == "POStatusNotIssued") {
                var errorMessage = 'This PO Status is ' + msg.Data.Status + '; it should be in ISSUED status in order to enter an invoice';
                ShowStatus("error", errorMessage, formElemnt);
            }
            else if (msg.Status == "POContainsInvoice") {
                var errorMessage = "An invoice already exits for this PO; you cannot add another one";
                ShowStatus("error", errorMessage, formElemnt);
            }
            else if (msg.Status == "PO_ALREADY_PAID") {
                var errorMessage = "PO was paid by the member";
                ShowStatus("error", errorMessage, formElemnt);
            }
            else if (msg.Status == "PO_PAID_BY_CC") {

                var errorMessage = "PO was paid by credit card.";
                ShowStatus("error", errorMessage, formElemnt);
            }
            else if (msg.Status == "Success") {

                $("#btnVerifyPO_" + suffixVendorInvoiceID).hide();
                $("#btnContinuePO_" + suffixVendorInvoiceID).show();
                $("#btnResetPO_" + suffixVendorInvoiceID).show();
                var message = "PO Verified, Click CONTINUE ";
                $("#PONumber_" + suffixVendorInvoiceID).attr("data-POID", msg.Data.POID);
                $("#PONumber_" + suffixVendorInvoiceID).attr("data-VendorLocationID", msg.Data.VendorLocationID);
                $("#PONumber_" + suffixVendorInvoiceID).attr('readonly', 'readonly');
                ShowStatus("success", message, formElemnt);
            }
            else {
                var errorMessage = msg.Status;
                ShowStatus("error", errorMessage, formElemnt);
            }
            if (msg.Data != null) {
                vendorInvoiceIDofPO = msg.Data.VendorInvoiceID;
                poID = msg.Data.POID;
                vendorLocationID = msg.Data.VendorLocationID;
            }
            BindVendorInvoiceProcessingDetails(vendorInvoiceIDofPO, suffixVendorInvoiceID, poNumber, poID, vendorLocationID);
        }
    });
}

function BindVendorInvoiceProcessingDetails(vendorInvoiceIDofPO, suffixVendorInvoiceID, poNumber, poID, vendorLocationID) {
    $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs({
        ajaxOptions: {
            data: { vendorInvoiceID: vendorInvoiceIDofPO, vendorID: 0 }
        }
    });
    $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);
    setTimeout(function (e) {
        $("#frmVendorInvoiceContainerForDirtyFlag_" + vendorInvoiceIDofPO).removeClass('disabled');
        $("#frmVendorInvoiceDetails_" + vendorInvoiceIDofPO + " input").each(function () {
            $(this).attr("disabled", "disabled");
        });

        $("#VendorInvoiceStatusID_" + vendorInvoiceIDofPO).data("kendoComboBox").enable(false);
        $("#ReceiveContactMethodID_" + vendorInvoiceIDofPO).data("kendoComboBox").enable(false);
        $("#PaymentDifferenceReason_" + vendorInvoiceIDofPO).data("kendoComboBox").enable(false);
        $("#ETAHours_" + vendorInvoiceIDofPO).data("kendoComboBox").enable(false);

        $("#InvoiceDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").enable(false);
        $("#ReceivedDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").enable(false);
        $("#ToBePaidDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").enable(false);
        $("#btnCancelVendorInvoiceInfoSection_" + vendorInvoiceIDofPO).attr("disabled");
        if (vendorInvoiceIDofPO > 0) {
            $("#frmVendorInvoiceDetails_" + vendorInvoiceIDofPO + " input").each(function () {
                $(this).val('');
            });
            $("#VendorInvoiceStatusID_" + vendorInvoiceIDofPO).data("kendoComboBox").select(0);
            $("#ReceiveContactMethodID_" + vendorInvoiceIDofPO).data("kendoComboBox").select(0);
            $("#PaymentDifferenceReason_" + vendorInvoiceIDofPO).data("kendoComboBox").select(0);
            $("#InvoiceDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").value('');
            $("#ReceivedDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").value('');
            $("#ToBePaidDate_" + vendorInvoiceIDofPO).data("kendoDatePicker").value('');
        }
        if (!vendorInvoiceIDofPO > 0) {
            BindPODetails(poNumber, suffixVendorInvoiceID);
            BindVendorLocationDetails(poID, vendorLocationID, suffixVendorInvoiceID);
        }
    }, 1000)
}

function resetInvoiceTab(sender, suffixVendorInvoiceID) {
    $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);
    $("#btnVerifyPO_" + suffixVendorInvoiceID).show();
    $("#PONumber_" + suffixVendorInvoiceID).removeAttr('readonly');
    $("#btnContinuePO_" + suffixVendorInvoiceID).hide();
    $("#btnResetPO_" + suffixVendorInvoiceID).hide();
    var formElemnt = $("#frmPoNumberVerfiy_" + suffixVendorInvoiceID);
    HideStatus(formElemnt);

}

function continueToInvoiceTab(sender, suffixVendorInvoiceID) {

    var formElemnt = $("#frmPoNumberVerfiy_" + suffixVendorInvoiceID);
    HideStatus(formElemnt);
    //$("#btnContinuePO_" + suffixVendorInvoiceID).addClass('disabled', 'disabled');
    $("#btnVerifyPO_" + suffixVendorInvoiceID).show().attr("disabled", "disabled");
    $("#PONumber_" + suffixVendorInvoiceID).attr("disabled", "disabled");

    $("#btnContinuePO_" + suffixVendorInvoiceID).hide();
    $("#btnResetPO_" + suffixVendorInvoiceID).hide();

    $("#frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID).removeClass('disabled');
    $("#frmVendorInvoiceDetails_" + suffixVendorInvoiceID + " input").each(function () {
        $(this).removeAttr("disabled");
        //$(this).attr("disabled", "disabled");
    });
    $("#VendorInvoiceStatusID_" + suffixVendorInvoiceID).data("kendoComboBox").enable(true);
    $("#ReceiveContactMethodID_" + suffixVendorInvoiceID).data("kendoComboBox").enable(true);
    $("#PaymentDifferenceReason_" + suffixVendorInvoiceID).data("kendoComboBox").enable(true);
    $("#ETAHours_" + suffixVendorInvoiceID).data("kendoComboBox").enable(true);

    $("#ETAMinutes_" + suffixVendorInvoiceID).data("kendoComboBox").enable(true);
    $("#InvoiceDate_" + suffixVendorInvoiceID).data("kendoDatePicker").enable(true);
    $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker").enable(true);
    $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").enable(true);
    $("#btnCancelVendorInvoiceInfoSection_" + suffixVendorInvoiceID).removeAttr("disabled");
    /* Bug:1676*/
    $("#frmVendorInvoiceDetails_" + suffixVendorInvoiceID + " input").each(function () {
        $(this).val('');
        //$(this).attr("disabled", "disabled");
    });
    $("#VendorInvoiceStatusID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
    $("#ReceiveContactMethodID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
    $("#PaymentDifferenceReason_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
    //$("#ETAMinutes_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
    $("#InvoiceDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
    $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
    $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
    /* Bug:1676*/
    // Populate PO, Processing and Vendor Details.
    var $poNumber = $("#PONumber_" + suffixVendorInvoiceID);
    var poNumber = $poNumber.val();
    var poId = $poNumber.attr("data-POID");
    var vendorLocationId = $poNumber.attr("data-VendorLocationID");

    // PO Details
    BindPODetails(poNumber, suffixVendorInvoiceID);

    // Vendor Details
    BindVendorLocationDetails(poId, vendorLocationId, suffixVendorInvoiceID);
}

function BindPODetails(poNumber, suffixVendorInvoiceID) {
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/_PODetails',
        data: { PONumber: poNumber },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        modal: true,
        success: function (msg) {
            $("#divPODetails_" + suffixVendorInvoiceID).html(msg);
        }

    });
}

function BindVendorLocationDetails(poId, vendorLocationId, suffixVendorInvoiceID) {
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/_BillingDetails',
        data: { poID: poId, vendorLocationID: vendorLocationId },
        traditional: true,
        cache: false,
        ajax: true,
        async: true,
        success: function (msg) {
            $("#divVendorDetails_" + suffixVendorInvoiceID).html(msg);
        }
    });
}

Date.prototype.addDays = function (days) {
    this.setDate(this.getDate() + days);
    return this;
};

function HandleVendorInvoiceReceiveMethodChange(e, suffixVendorInvoiceID, manualWaitInDays) {
    //ToBePaidDate_
    var combo = e.sender;
    var receiveMethodID = combo.value();
    var receiveMethod = combo.text();
    var date = new Date();
    var currentDate = new Date();
    var receiveDate = $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value();
    if (receiveDate != null || receiveDate != undefined) {
        var currentDate = new Date(receiveDate.getFullYear(), receiveDate.getMonth(), receiveDate.getDate());
        currentDate.addDays(manualWaitInDays);

    }
    if (receiveMethod == 'Web') {
        $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value(date);
    }
    else {
        $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value(currentDate);
    }
}

function VendorInvoiceFlags() {
    AllowLapsedPOs = false;
    AllowLowerPOAmount = false;
}

var vendorInvoiceFlags = [];

function SubmitInvoice(sender, suffixVendorInvoiceID) {

    var allowLapsedPOs = false;
    var allowLowerPOAmount = false;

    var currentInvoiceFlags = vendorInvoiceFlags[suffixVendorInvoiceID];
    if (currentInvoiceFlags != null) {
        allowLapsedPOs = currentInvoiceFlags.AllowLapsedPOs;
        allowLowerPOAmount = currentInvoiceFlags.AllowLowerPOAmount;
    }

    var formElemnt = $("#frmVendorInvoiceDetails_" + suffixVendorInvoiceID);
    var errorFound = false;
    if (formElemnt.validationEngine('validate') == false) {
        errorFound = true;
    }

    var vendorInvoiceCombo = $("#VendorInvoiceStatusID_" + suffixVendorInvoiceID).data("kendoComboBox");
    var receiveContactCombo = $("#ReceiveContactMethodID_" + suffixVendorInvoiceID).data("kendoComboBox");
    var etaMinutesCombo = $("#ETAMinutes_" + suffixVendorInvoiceID).data("kendoComboBox");
    var invoiceDatePicker = $("#InvoiceDate_" + suffixVendorInvoiceID).data("kendoDatePicker");
    var receiveDatePicker = $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker");
    var invoiceAmountPicker = $("#InvoiceAmount_" + suffixVendorInvoiceID).data("kendoNumericTextBox");
    var paymentAmountPicker = $("#PaymentAmount_" + suffixVendorInvoiceID).data("kendoNumericTextBox");
    var last8OfVin = $.trim($("#Last8OfVIN_" + suffixVendorInvoiceID).val());
    var paymentDifferenceReasonCombo = $("#PaymentDifferenceReason_" + suffixVendorInvoiceID).data("kendoComboBox");

    var invoiceAmountValue = invoiceAmountPicker.value();
    var paymentAmountValue = paymentAmountPicker.value();

    if ($.trim(invoiceAmountValue).length == 0 || invoiceAmountValue == 0) {
        ShowValidationMessage($('input[id=InvoiceAmount_' + suffixVendorInvoiceID + ']'), "*Please select Invoice Amount");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[id=InvoiceAmount_' + suffixVendorInvoiceID + ']'));
    }
    if ($.trim(paymentAmountValue).length == 0 || paymentAmountValue == 0) {
        ShowValidationMessage($('input[id=PaymentAmount_' + suffixVendorInvoiceID + ']'), "*Please select Pay Amount");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[id=PaymentAmount_' + suffixVendorInvoiceID + ']'));
    }

    if ($.trim(vendorInvoiceCombo.value()).length == 0) {
        ShowValidationMessage($('input[id=VendorInvoiceStatusID_' + suffixVendorInvoiceID + ']'), "* Status field is required.");
        errorFound = true;
    }
    else if (vendorInvoiceCombo.text() == 'Exception') {
        //ShowValidationMessage($('input[id=VendorInvoiceStatusID_' + suffixVendorInvoiceID + ']'), "Status cannot be set to Exception");
        openAlertMessage("Users cannot change status to Exception");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[id=VendorInvoiceStatusID_' + suffixVendorInvoiceID + ']'));
    }

    if ($.trim(receiveContactCombo.value()).length == 0) {
        ShowValidationMessage($('input[id=ReceiveContactMethodID_' + suffixVendorInvoiceID + ']'), "* Receive Method field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[id=ReceiveContactMethodID_' + suffixVendorInvoiceID + ']'));
    }

    //        if ($.trim(etaMinutesCombo.value()).length == 0) {
    //            ShowValidationMessage($('input[id=ETAMinutes_' + suffixVendorInvoiceID + ']'), "* Minutes field is required.");
    //            errorFound = true;
    //        }
    //        else {
    //            HideValidationMessage($('input[id=ETAMinutes_' + suffixVendorInvoiceID + ']'));
    //        }
    if (last8OfVin.length > 0 && last8OfVin.length < 8) {
        ShowValidationMessage($("#Last8OfVIN_" + suffixVendorInvoiceID), "* Input is not valid");
        errorFound = true;
    }
    else {
        HideValidationMessage($("#Last8OfVIN_" + suffixVendorInvoiceID));
    }

    if ($.trim(receiveDatePicker.value()).length == 0) {
        ShowValidationMessage($('input[id=ReceivedDate_' + suffixVendorInvoiceID + ']'), "* This field is required.");
        errorFound = true;
    }
    else {
        HideValidationMessage($('input[id=ReceivedDate_' + suffixVendorInvoiceID + ']'));
    }

    if (errorFound == true) {
        return false;
    }

    var formData = $(formElemnt).serializeArray();

    var ETAHours = $("#ETAHours_" + suffixVendorInvoiceID).data("kendoComboBox").value();

    var ETAMinutes = etaMinutesCombo.value();


    //        //Email = null
    formData.push({ name: "VendorInvoiceDetails.VendorInvoiceStatusID", value: vendorInvoiceCombo.value() });
    formData.push({ name: "VendorInvoiceDetails.ReceiveContactMethodID", value: receiveContactCombo.value() });
    formData.push({ name: "VendorInvoiceDetails.ActualETAMinutes", value: ETAMinutes });
    formData.push({ name: "VendorInvoiceDetails.ETAHours", value: ETAHours });

    formData.push({ name: "VendorInvoiceDetails.PaymentAmount", value: paymentAmountPicker.value() });
    formData.push({ name: "VendorInvoiceDetails.InvoiceAmount", value: invoiceAmountPicker.value() });
    formData.push({ name: "VendorInvoiceDetails.VendorInvoicePaymentDifferenceReasonCodeID", value: paymentDifferenceReasonCombo.value() });
    formData.push({ name: "AllowLapsedPOs", value: allowLapsedPOs });
    formData.push({ name: "AllowLowerPOAmount", value: allowLowerPOAmount });

    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorInvoices/ValidateInvoice',
        traditional: true,
        data: formData,
        cache: false,
        async: true,
        global: false,
        success: function (msg) {
            if (msg.Status == "Success") {
                if ($("#divCopyOfInvoice_" + suffixVendorInvoiceID).find($(".k-upload-selected")).length > 0) {
                    console.log("File uploaded so going via Kendo Upload");
                    $("#divCopyOfInvoice_" + suffixVendorInvoiceID).find($(".k-upload-selected")).click();
                }
                else {
                    console.log("File not uploaded so posting via AJAX.");
                    $.ajax({
                        type: 'POST',
                        url: '/VendorManagement/VendorInvoices/SaveVendorInvoiceInformation',
                        data: formData,
                        traditional: true,
                        cache: false,
                        ajax: true,
                        async: true,
                        modal: true,
                        success: function (msg) {
                            if (msg.Status == "Success") {

                                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                                openAlertMessage("Data saved successfully");

                                //close and reopen the tab in Edit mode.
                                var vendorInvoiceDetails = msg.Data;
                                if (vendorInvoiceDetails != null) {
                                    DeleteTab(suffixVendorInvoiceID);
                                    addTab(vendorInvoiceDetails.InvoiceNumber, vendorInvoiceDetails.InvoiceNumber, vendorInvoiceDetails.VendorInvoiceID, vendorInvoiceDetails.VendorID);
                                }
                                else {
                                    $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);
                                }
                                $("#GrdVendorInvoices").data('kendoGrid').dataSource.read();
                            }
                            else if (msg.Status == "BusinessRuleFail") {
                                var errorMessage = msg.ErrorMessage;
                                var currentInvoiceFlags = vendorInvoiceFlags[suffixVendorInvoiceID];
                                if (currentInvoiceFlags == null) {
                                    currentInvoiceFlags = new VendorInvoiceFlags();
                                    vendorInvoiceFlags[suffixVendorInvoiceID] = currentInvoiceFlags;
                                }
                                switch (msg.ErrorMessage) {
                                    case 'PO_NOT_EXISTS':
                                        errorMessage = 'PO number was not found, please try again';
                                        break;
                                    case 'PO_PAID_BY_CC':
                                        errorMessage = 'PO was paid by credit card.';
                                        break;
                                    case 'PO_ALREADY_PAID':
                                        errorMessage = 'PO was paid by the member';
                                        break;
                                    case 'PO_NOT_ISSUED':
                                        errorMessage = 'PO number cannot be verified, please check the number and try again. If you think the PO number is valid, please contact your Vendor Rep';
                                        break;
                                    case 'PO_ALREADY_INVOICED':
                                        errorMessage = 'An invoice has already been submitted for this PO';
                                        break;

                                    case 'PO_LAPSED':
                                        errorMessage = 'Invoice is over 90 days old.  Do you want to go ahead and pay the invoice?';

                                        $.modal.confirmYesNo(errorMessage, function () {
                                            currentInvoiceFlags.AllowLapsedPOs = true;
                                            SubmitInvoice(sender, suffixVendorInvoiceID);
                                        }, function () {

                                        });
                                        errorMessage = '';
                                        break;
                                    case 'APP_CONFIG_VALUE_NOT_FOUND':
                                        errorMessage = 'Application configuration item - MaximumInvoiceAmountThreshold is not set up';
                                        break;
                                    case 'AMOUNT_THRESHOLD_EXCEEDED':
                                        errorMessage = 'Invoice amount does not match the PO amount';
                                        break;

                                    case 'LOWER_PO_AMOUNT':
                                        errorMessage = 'Pay amount is less than half of the PO amount. Do you want to go ahead and pay the invoice?'; //'Please check the invoice amount, it is much lower than the PO amount';

                                        $.modal.confirmYesNo(errorMessage, function () {
                                            currentInvoiceFlags.AllowLowerPOAmount = true;
                                            SubmitInvoice(sender, suffixVendorInvoiceID);
                                        }, function () {

                                        });
                                        errorMessage = '';
                                        break;
                                        break;
                                    case 'MISSING_BILLING_ADDRESS':
                                        errorMessage = 'Missing vendor billing address';
                                        break;
                                    case 'MISSING_TAX_ID':
                                        errorMessage = 'Missing Tax ID, please go to My Account and enter your Tax ID';
                                        break;
                                    default:
                                        break;

                                }
                                if ($.trim(errorMessage).length > 0) {
                                    openAlertMessage(errorMessage);
                                }
                            }
                        }

                    });
                }
            }
            else if (msg.Status == "BusinessRuleFail") {
                var errorMessage = msg.ErrorMessage;
                var currentInvoiceFlags = vendorInvoiceFlags[suffixVendorInvoiceID];
                if (currentInvoiceFlags == null) {
                    currentInvoiceFlags = new VendorInvoiceFlags();
                    vendorInvoiceFlags[suffixVendorInvoiceID] = currentInvoiceFlags;
                }
                switch (msg.ErrorMessage) {
                    case 'PO_NOT_EXISTS':
                        errorMessage = 'PO number was not found, please try again';
                        break;
                    case 'PO_PAID_BY_CC':
                        errorMessage = 'PO was paid by credit card.';
                        break;
                    case 'PO_ALREADY_PAID':
                        errorMessage = 'PO was paid by the member';
                        break;
                    case 'PO_NOT_ISSUED':
                        errorMessage = 'PO number cannot be verified, please check the number and try again. If you think the PO number is valid, please contact your Vendor Rep';
                        break;
                    case 'PO_ALREADY_INVOICED':
                        errorMessage = 'An invoice has already been submitted for this PO';
                        break;

                    case 'PO_LAPSED':
                        errorMessage = 'Invoice is over 90 days old.  Do you want to go ahead and pay the invoice?';

                        $.modal.confirmYesNo(errorMessage, function () {
                            currentInvoiceFlags.AllowLapsedPOs = true;
                            SubmitInvoice(sender, suffixVendorInvoiceID);
                        },
                            function () {

                            });
                        errorMessage = '';
                        break;
                    case 'APP_CONFIG_VALUE_NOT_FOUND':
                        errorMessage = 'Application configuration item - MaximumInvoiceAmountThreshold is not set up';
                        break;
                    case 'AMOUNT_THRESHOLD_EXCEEDED':
                        errorMessage = 'Invoice amount does not match the PO amount';
                        break;

                    case 'LOWER_PO_AMOUNT':
                        errorMessage = 'Pay amount is less than half of the PO amount. Do you want to go ahead and pay the invoice?'; //'Please check the invoice amount, it is much lower than the PO amount';

                        $.modal.confirmYesNo(errorMessage, function () {
                            currentInvoiceFlags.AllowLowerPOAmount = true;
                            SubmitInvoice(sender, suffixVendorInvoiceID);
                        },
                            function () {

                            });
                        errorMessage = '';
                        break;
                        break;
                    case 'MISSING_BILLING_ADDRESS':
                        errorMessage = 'Missing vendor billing address';
                        break;
                    case 'MISSING_TAX_ID':
                        errorMessage = 'Missing Tax ID, please go to My Account and enter your Tax ID';
                        break;
                    default:
                        break;

                }
                if ($.trim(errorMessage).length > 0) {
                    openAlertMessage(errorMessage);
                }
            }
        }
    });
}

function SaveVendorInvoiceInfoSection(sender, suffixVendorInvoiceID) {
    SubmitInvoice(sender, suffixVendorInvoiceID);
    return false;
}

function CancelVendorInvoiceInfSection(sender, suffixVendorInvoiceID) {
    if (IsMyContainerDirty("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID)) {
        var message = "Changes will not be saved. Do you want to continue and lose the changes?";
        $.modal.confirm(message, function () {
            if (suffixVendorInvoiceID > 0) {
                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                //Refresh the page 
                $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);
            }
            else {
                $("#frmVendorInvoiceDetails_" + suffixVendorInvoiceID + " input").each(function () {
                    $(this).val('');
                    //$(this).attr("disabled", "disabled");
                });
                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                $("#VendorInvoiceStatusID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
                $("#ReceiveContactMethodID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
                $("#PaymentDifferenceReason_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
                $("#ETAMinutes_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
                $("#InvoiceDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
                $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
                $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
            }
        }, function () {
            return false;
        });
    }
    else {
        if (suffixVendorInvoiceID > 0) {
            CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
            //Refresh the page 
            $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);
        }
        else {
            $("#frmVendorInvoiceDetails_" + suffixVendorInvoiceID + " input").each(function () {
                $(this).val('');
                //$(this).attr("disabled", "disabled");
            });
            CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
            $("#VendorInvoiceStatusID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
            $("#ReceiveContactMethodID_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
            $("#ETAMinutes_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
            $("#InvoiceDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
            $("#ReceivedDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
            $("#ToBePaidDate_" + suffixVendorInvoiceID).data("kendoDatePicker").value('');
            $("#PaymentDifferenceReason_" + suffixVendorInvoiceID).data("kendoComboBox").select(0);
        }
    }
}


function fnVendorInvoiceDownloadCopyOfInvoice(documentID, documentName, suffixVendorInvoiceID) {
    var hiddenForm = $("#frmGetVendorInvoiceDocument_" + suffixVendorInvoiceID);
    hiddenForm.find("#documentID").val(documentID);
    hiddenForm.find("#isContentFromFile").val(false);
    hiddenForm.find("#recordId").val(suffixVendorInvoiceID);
    hiddenForm.find("#documentName").val(documentName);
    hiddenForm.submit();
}

function fnVendorInvoiceDeleteCopyOfInvoice(documentID, entityName, suffixVendorInvoiceID) {
    $.modal.confirm('The uploaded invoice copy will be permanently removed.', function () {
        $.ajax({
            type: 'POST',
            url: '/Common/Documents/Delete',
            traditional: true,
            cache: false,
            data: { documentID: documentID, entityName: entityName, recordID: suffixVendorInvoiceID },
            async: false,
            success: function (msg) {
                CleanMyContainer("frmVendorInvoiceContainerForDirtyFlag_" + suffixVendorInvoiceID);
                openAlertMessage("Invoice Copy deleted successfully.");

                $('#VendorInvoiceDetailsTab_' + suffixVendorInvoiceID).tabs('load', 0);

                $("#GrdVendorInvoices").data('kendoGrid').dataSource.read();
            }
        });
    }, function () {

    });
}