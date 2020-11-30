function ClientBillingViewSource(entityName, entityKey, tabObject) {
    if (tabObject == null) {
        openAlertMessage('Unable to find Container to add new tab');
        return false;
    }
    if (entityName != undefined && entityKey != undefined) {
        var tabTitle = '';
        if (entityName == "ServiceRequest") {
            tabTitle = 'SR-' + entityKey;
            if (canAddGenericTabInCurrentContainer(tabTitle, tabObject)) {
                $.ajax({
                    type: 'GET',
                    url: '/Application/History/GetServiceRequestDetails',
                    traditional: true,
                    data: { serviceRequestID: entityKey },
                    cache: false,
                    async: true,
                    success: function (msg) {
                        addGenericTabWithCurrentContainer(tabTitle, tabObject, msg);
                    }
                });
            }
        }
        else if (entityName == "PurchaseOrder") {
            tabTitle = 'PO-' + entityKey;
            if (canAddGenericTabInCurrentContainer(tabTitle, tabObject)) {
                $.ajax({
                    type: 'POST',
                    url: '/Application/History/PODetails',
                    traditional: true,
                    data: { poId: entityKey, pageMode: 'view' },
                    cache: false,
                    async: true,
                    success: function (msg) {
                        addGenericTabWithCurrentContainer(tabTitle, tabObject, msg);
                    }
                });
            }
        }
        else if (entityName == "Claim") {
            tabTitle = 'Claim-' + entityKey;
            if (canAddGenericTabInCurrentContainer(tabTitle, tabObject)) {
                $.ajax({
                    type: 'GET',
                    url: '/Claims/Claim/_ClaimDetails',
                    traditional: true,
                    data: { claimID: entityKey },
                    cache: false,
                    async: true,
                    success: function (msg) {
                        addGenericTabWithCurrentContainer(tabTitle, tabObject, msg);
                    }
                });
            }
        }
        else if (entityName == "VendorInvoice") {
            tabTitle = 'VendorInvoice-' + entityKey;
            if (canAddGenericTabInCurrentContainer(tabTitle, tabObject)) {
                $.ajax({
                    type: 'GET',
                    url: '/VendorManagement/VendorInvoices/_VendorInvoiceDetails',
                    traditional: true,
                    data: { vendorInvoiceID: entityKey, vendorID: 0 },
                    cache: false,
                    async: true,
                    success: function (msg) {
                        addGenericTabWithCurrentContainer(tabTitle, tabObject, msg);
                    }
                });
            }
        }
        else {
            openAlertMessage("View Source is not Configured for current entity");
        }
    }
    else {
        openAlertMessage("Entity Type or Record Number not found !");
    }
}


function SaveBillableEventProcessingDetails(recordID, tabObjectReference, gridName, tabName) {
   
    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container Tab Container');
        return false;
    }

    var status = $('#BillingStatusID_' + recordID).data('kendoComboBox').text();
    var isExcludedSelected = $('#IsExcluded_' + recordID).is(':checked');
    var isAdjustSelected = $('#IsAdjusted_' + recordID).is(':checked');
    var isQuantityAndAmountEditable = $('#IsQuantityAndAmountEditable_' + recordID).val();
   
    var adjustmentReasonText = $('#AdjustmentReasonID_' + recordID).data('kendoComboBox').text();
    var adjustmentReasonOther = $('#AdjustmentReasonOther_' + recordID).val();

    var excludedReasonText = $('#BillingExcludeReasonID_' + recordID).data('kendoComboBox').text();
    var excludedReasonOther = $('#ExcludeReasonOther_' + recordID).val();

    if ($.trim(adjustmentReasonOther).length == 0 && adjustmentReasonText == "Other") {
        $('#ClientBillableTabDepthDetails_' + recordID).tabs({ selected: 0 });
        ShowValidationMessage($("input[id= AdjustmentReasonOther_" + recordID + "]"), "* Reason Other is required.");
        return false;
    }
    else {
        HideValidationMessage($("input[id= AdjustmentReasonOther_" + recordID + "]"));
    }

    if ($.trim(excludedReasonOther).length == 0 && excludedReasonText == "Other") {
        $('#ClientBillableTabDepthDetails_' + recordID).tabs({ selected: 1 });
        ShowValidationMessage($("input[id= ExcludeReasonOther_" + recordID + "]"), "* Reason Other is required.");
        return false;
    }
    else {
        HideValidationMessage($("input[id= ExcludeReasonOther_" + recordID + "]"));
    }

    var quantity = $('#Quantity_' + recordID).data('kendoNumericTextBox').value();
    var eventAmount = $('#EventAmount_' + recordID).data('kendoNumericTextBox').value();
    if (isQuantityAndAmountEditable == "True") {
        if ($.trim(quantity).length == 0) {
            ShowValidationMessage($("input[id= Quantity_" + recordID + "]"), "* Quantity is required.");
            return false;
        }
        else {
            HideValidationMessage($("input[id= Quantity_" + recordID + "]"));
        }
        if ($.trim(eventAmount).length == 0) {
            ShowValidationMessage($("input[id= EventAmount_" + recordID + "]"), "* Event Amount is required.");
            return false;
        }
        else {
            HideValidationMessage($("input[id= EventAmount_" + recordID + "]"));
        }
    }

    if (isAdjustSelected) {
        var isAdjustValid = true;
        var adjustmentAmount = $('#AdjustmentAmount_' + recordID).data('kendoNumericTextBox').value();
        var adjustmentReasonID = $('#AdjustmentReasonID_' + recordID).data('kendoComboBox').value();
        var $invoiceAmountFormatted = $("#AdjustmentAmount_" + recordID).siblings(".k-formatted-value");
        $invoiceAmountFormatted.attr("id", "JunkAdjustmentAmount_" + recordID);
        $('#ClientBillableTabDepthDetails_' + recordID).tabs({ selected: 0 });

        if (adjustmentReasonID == null || adjustmentReasonID == undefined || adjustmentReasonID == '') {
            ShowValidationMessage($("input[name= AdjustmentReasonID_" + recordID + "_input]"), "* Reason is required.");
            isAdjustValid = false;
        }
        else {
            HideValidationMessage($("input[name= AdjustmentReasonID_" + recordID + "_input]"));
        }

        if ($.trim(adjustmentReasonOther).length == 0 && adjustmentReasonText == "Other") {
            ShowValidationMessage($("input[id= AdjustmentReasonOther_" + recordID + "]"), "* Reason Other is required.");
            isAdjustValid = false;
        }
        else {
            HideValidationMessage($("input[id= AdjustmentReasonOther_" + recordID + "]"));
        }

        if (adjustmentAmount == 0 || adjustmentAmount == null || adjustmentAmount == undefined) {
            ShowValidationMessage($invoiceAmountFormatted, "Please enter a amount");
            isAdjustValid = false;
        }
        else {
            HideValidationMessage($invoiceAmountFormatted);
        }

        if (!isAdjustValid) {
            return false;
        }
    }

    if (isExcludedSelected) {
        var isExcludeValid = true;
        var excludedReasonCombo = "BillingExcludeReasonID_" + recordID;
        var excludedReasonID = $('#BillingExcludeReasonID_' + recordID).data('kendoComboBox').value();
        $('#ClientBillableTabDepthDetails_' + recordID).tabs({ selected: 1 });

        if (excludedReasonID == null || excludedReasonID == undefined || $.trim(excludedReasonID).length == 0) {
            ShowValidationMessage($('input[name= "' + excludedReasonCombo + '_input"]'), "* Reason is required.");
            isExcludeValid = false;
        }
        else {
            HideValidationMessage($('input[name= "' + excludedReasonCombo + '_input"]'));
        }

        if ($.trim(excludedReasonOther).length == 0 && excludedReasonText == "Other") {
            ShowValidationMessage($("input[id= ExcludeReasonOther_" + recordID + "]"), "* Reason Other is required.");
            isExcludeValid = false;
        }
        else {
            HideValidationMessage($("input[id= ExcludeReasonOther_" + recordID + "]"));
        }

        if (!isExcludeValid) {
            return false;
        }
    }


    if (status != undefined && status != null) {
        if (status == 'Excluded') {
            if (!isExcludedSelected) {
                $('#ClientBillableTabDepthDetails_' + recordID).tabs({ selected: 1 });
                ShowValidationMessage($("input[id= IsExcluded_" + recordID + "]"), "Users cannot change status to Excluded,  you must fill in the Exclude tab information to exclude this event.");
                return false;
            }
            else {
                HideValidationMessage($("input[id= IsExcluded_" + recordID + "]"));
            }
        }
    }

    if ($('#formBillingDetailMaintenance_' + recordID).validationEngine("validate") == true) {
        var postData = [];
        postData.push({ name: "BillingInvoiceDetailID", value: recordID })
        postData.push({ name: "InvoiceDetailStatusID", value: $('#BillingStatusID_' + recordID).data('kendoComboBox').value() })
        postData.push({ name: "BillingDispositionStatusID", value: $('#BillingDispositionStatusID_' + recordID).data('kendoComboBox').value() })


        postData.push({ name: "AdjustmentReasonID", value: $('#AdjustmentReasonID_' + recordID).data('kendoComboBox').value() })
        postData.push({ name: "AdjustmentReasonOther", value: $('#AdjustmentReasonOther_' + recordID).val() })
        postData.push({ name: "AdjustmentComment", value: $('#AdjustmentComment_' + recordID).val() })
        postData.push({ name: "AdjustmentAmount", value: $('#AdjustmentAmount_' + recordID).data('kendoNumericTextBox').value() })

        postData.push({ name: "ExcludeReasonID", value: $('#BillingExcludeReasonID_' + recordID).data('kendoComboBox').value() })
        postData.push({ name: "ExcludeReasonOther", value: $('#ExcludeReasonOther_' + recordID).val() })
        postData.push({ name: "ExcludeComment", value: $('#ExcludeComment_' + recordID).val() })

        postData.push({ name: "EventAmount", value: eventAmount })
        postData.push({ name: "Quantity", value: quantity })

        postData.push({ name: "IsAdjusted", value: $('#IsAdjusted_' + recordID).is(':checked') })
        postData.push({ name: "IsExcluded", value: $('#IsExcluded_' + recordID).is(':checked') })

        postData.push({ name: "InternalComment", value: $('#InternalComment_' + recordID).val() });
        postData.push({ name: "ClientNote", value: $('#ClientNotesComment_' + recordID).val() });


        $.ajax({
            type: 'POST',
            url: '/ClientManagement/ClientBillableEventProcessing/ClientBillableEventProcessingSaveDetails',
            data: postData,
            success: function (msg) {
                CleanMyContainer('formBillingDetailMaintenance_' + recordID);
                deleteGenericTab('formBillingDetailMaintenance_' + recordID, tabObjectReference);
                var tabTitle = "Detail " + recordID;
                if (canAddGenericTabInCurrentContainer(tabTitle, tabObjectReference)) {
                    $.ajax({
                        type: 'POST',
                        url: '/ClientManagement/ClientBillableEventProcessing/_BillingInvoiceDetails',
                        traditional: true,
                        data: { recordID: recordID, mode: "Edit", gridName: gridName, tabName: tabName },
                        cache: false,
                        async: true,
                        success: function (msg) {
                            if (gridName != undefined && $('#' + gridName).data('kendoGrid') != undefined) {
                                $('#' + gridName).data('kendoGrid').dataSource.read();
                            }
                            addGenericTabWithCurrentContainer(tabTitle, tabObjectReference, msg);
                        }
                    });
                }
            }
        });
    }
    return false;
}

function CancelBillableEventProcessingDetails(recordID, tabObjectReference, gridName, tabName) {

    if (tabObjectReference == null) {
        openAlertMessage('Unable to find Container');
        return false;
    }

    var activeIndex = tabObjectReference.tabs('option', 'selected');

    if (IsMyContainerDirty("formBillingDetailMaintenance_" + recordID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            tabObjectReference.tabs('remove', activeIndex);
            tabObjectReference.tabs('refresh');
            tabObjectReference.tabs('select', 0);
            CleanMyContainer("formBillingDetailMaintenance_" + recordID);
            setFousRefreshGridIfExists(tabObjectReference, tabName, gridName);
        }, function () {
            return false;
        });
    }
    else {
        tabObjectReference.tabs('remove', activeIndex);
        tabObjectReference.tabs('refresh');
        tabObjectReference.tabs('select', 0);

        setFousRefreshGridIfExists(tabObjectReference, tabName, gridName);
    }
}