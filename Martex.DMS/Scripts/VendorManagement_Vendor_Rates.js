var POPUP_Vendor_Rates_Existing_Rates = null;
function GrdVendorRatesAndSchedule_OnDataBound(e) {
    $(".k-grid-View").addClass("with-tooltip").html("<span class='k-icon k-i-search'/>");
    $(".k-grid-Edit").addClass("with-tooltip").html("<span class='k-icon k-edit'/>");
    $(".k-grid-Delete").addClass("with-tooltip").html("<span class='k-icon k-delete'/>");

}

function Grid_ManageVendorRatesAndSchedule(e, data, vendorID) {
    var contractRateScheduleID = 0;
    if (e != null) {
        e.preventDefault();
        contractRateScheduleID = data.dataItem($(e.currentTarget).closest("tr")).ContractRateScheduleID;
        GetVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, e.data.commandName);
    }
    else {
        // Add Mode
        GetVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, "Add");
    }

    return false;
}

function ProcessVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, mode) {
    if (mode != "Delete" && mode != "Add") {
        $.ajax({
            url: '/VendorManagement/VendorHome/_Vendor_Rates_Details',
            data: { vendorID: vendorID, contractRateScheduleID: contractRateScheduleID, mode: mode },
            success: function (msg) {
                $('#PlaceHolder_Vendor_Rates_Details_' + vendorID).html(msg);
            }
        })
    }
    else if (mode == "Add") {
        $.ajax({
            url: '/VendorManagement/VendorHome/_Vendor_Rates_Add',
            data: { vendorID: vendorID, contractRateScheduleID: contractRateScheduleID },
            success: function (msg) {
                if (msg.Status == "Success") {
                    $.ajax({
                        url: '/VendorManagement/VendorHome/_Vendor_Rates_Details',
                        data: { vendorID: vendorID, contractRateScheduleID: contractRateScheduleID, mode: mode, contractID: msg.Data.ContractID },
                        success: function (msg) {
                            $('#PlaceHolder_Vendor_Rates_Details_' + vendorID).html(msg);
                        }
                    })
                }
                else if (msg.Status == "BusinessRuleFail") {
                    if (msg.Data.ContractCount == "0") {
                        openAlertMessage("There are no active contracts for this vendor. You must first add a contract before creating the rates");
                    }
                    else {
                        // Open a pop up to display contractID
                        ShowPopUpForVendorRatesExistingContracts(vendorID);
                    }
                }
            }
        })
    }
    else {
        var message = "Are you sure you want to delete this rate schedule?";
        $.modal.confirm(message, function () {
            $.ajax({
                url: '/VendorManagement/VendorHome/DeleteVendorRateSchedule',
                data: { vendorID: vendorID, contractRateScheduleID: contractRateScheduleID },
                success: function (msg) {
                    if (msg.Status == "Success") {
                        $('#GrdVendorRatesAndSchedule_' + vendorID).data('kendoGrid').dataSource.read();
                    }
                    else {
                        openAlertMessage("There is activity tied to this rate schedule so it cannot be deleted.  You can set the Status = Inactive instead.");
                    }
                }
            })
        }, function () {
            // Do Nothing
        });
    }
}

function GetVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, mode) {

    if (mode != "Delete") {
        if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + vendorID)) {
            var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
            $.modal.confirm(message, function () {

                //Hide Validation Message
                $('#frmVendorRateAndSchedules_' + vendorID).validationEngine("hideAll");
                // Do Nothing 
                CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
                $('#PlaceHolder_Vendor_RatesSchedules_Buttons_' + vendorID).hide();
                ProcessVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, mode);

            }, function () {
                return false;
            });
        }
        else {
            ProcessVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, mode);
        }
    }
    else {
        ProcessVendorRatesAndScheduleDisplayDetails(vendorID, contractRateScheduleID, mode);
    }
}


function SaveVendorRatesSchedules(vendorID) {

    var Combo_Vendor_Rates_Status = 'VendorContractRateScheduleStatusID_' + vendorID;
    var Form_Vendor_Rates = '#frmVendorRateAndSchedules_' + vendorID;
    var Form_Vendor_Rates_Data = null;

    var IsVendorRatesScheduleValid = true;

    if ($('#frmVendorRateAndSchedules_' + vendorID).validationEngine('validate') == false) {
        IsVendorRatesScheduleValid = false;
    }

    if (!ValidateCombo(Combo_Vendor_Rates_Status)) {
        IsVendorRatesScheduleValid = false;
    }

    if (IsVendorRatesScheduleValid) {
        Form_Vendor_Rates_Data = $(Form_Vendor_Rates).serializeArray();
        Form_Vendor_Rates_Data.push({ name: "CurrentRateSchedule.ContractRateScheduleStatusID", value: $('#' + Combo_Vendor_Rates_Status).data('kendoComboBox').value() })
        $.ajax({
            url: '/VendorManagement/VendorHome/SaveVendorRateSchedule',
            type: 'POST',
            data: Form_Vendor_Rates_Data,
            success: function (msg) {
                CleanMyContainer('frmVendorContainerForDirtyFlag_' + vendorID);
                //Refresh the page 
                $('#VendorDetailsTab_' + vendorID).tabs('load', 4);
            }
        })

    }
    return false;
}
function CancelVendorRatesSchedules(vendorID) {
    if (IsMyContainerDirty("frmVendorContainerForDirtyFlag_" + vendorID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {

            //Hide Validation Message
            $('#frmVendorRateAndSchedules_' + vendorID).validationEngine("hideAll");
            // Do Nothing 
            CleanMyContainer("frmVendorContainerForDirtyFlag_" + vendorID);
            //Refresh the page 
            $('#VendorDetailsTab_' + vendorID).tabs('load', 4);

        }, function () {
            // Do Nothing
        });
    }
    else {
        $('#VendorDetailsTab_' + vendorID).tabs('load', 4);
    }
}

var sendRatesPreviewLauncher = null;

function LaunchPreviewWindow(vendorID, rateScheduleID, source, title) {
    $.ajax({
        type: 'POST',
        url: '/VendorManagement/VendorHome/_PreviewRatesInfo',
        traditional: true,
        data: { vendorID: vendorID, rateScheduleID: rateScheduleID, source: source },
        cache: false,
        async: true,
        success: function (msg) {
            sendRatesPreviewLauncher = $("<div id='sendRatesPreviewLauncher' />").appendTo(document.body);
            sendRatesPreviewLauncher.kendoWindow({
                title: title,
                modal: true,
                width: 850, // CR: 1262
                height: GetPopupWindowHeight(),
                deactivate: function () {
                    this.destroy();
                },

                close: function (e) {
                    //Clear messages
                    ClearValidationMessages();
                    if (document.dialogResult == null || document.dialogResult == "CANCEL") {
                        document.dialogResult = null;
                        if (IsMyContainerDirty('frmSendRatesForPreview')) {
                            var prompt = PromptForDirtyFlag();
                            if (!prompt) {
                                e.preventDefault();
                                return false;
                            }
                            CleanMyContainer('frmSendRatesForPreview');
                        }
                    }
                    isdirty = false;
                    if (document.dialogResult == "OK") {
                        CleanMyContainer('frmSendRatesForPreview');
                    }

                    return true;
                }
            });
            sendRatesPreviewLauncher.data('kendoWindow').content(msg).center().open();

        }
    });
}

function VendorRatesSendAgreement(vendorID, rateScheduleID) {

    LaunchPreviewWindow(vendorID, rateScheduleID, "rates", "Send Rates Agreement");
    return false;
}

function VendorRatesSendWelcomeMessage(vendorID) {
    LaunchPreviewWindow(vendorID, null, "welcome", "Send Welcome Letter");
    return false;
}
function ShowPopUpForVendorRatesExistingContracts(vendorID) {
    $.ajax({
        url: '/VendorManagement/VendorHome/_Vendor_Rates_ExistingContracts',
        data: { vendorID: vendorID },
        success: function (msg) {
            POPUP_Vendor_Rates_Existing_Rates = $("<div id='POPUP_Vendor_Rates_Existing_Rates' />").appendTo(document.body);
            POPUP_Vendor_Rates_Existing_Rates.kendoWindow({
                title: 'Existing Vendor Contracts',
                modal: true,
                deactivate: function () {
                    this.destroy();
                },
                close: function (e) {
                    $('#frmVendorRatesExistingContractDetails').validationEngine('hideAll');
                    return true;
                }
            });
            POPUP_Vendor_Rates_Existing_Rates.data('kendoWindow').content(msg).center().open();
        }
    })
}

