
function ReloadPhoneList(recordID, entityName) {
    $.ajax({
        url: '/Common/Phone/GetScrollablePhoneList',
        type: 'GET',
        data: { recordID: recordID, entityName: entityName },
        success: function (msg) {

            var phoneListPlaceHolder = '#PlaceHolder_PhoneList_' + recordID;
            var phoneContainerPlaceHolder = '#PlaceHolder_PhoneContainer_' + recordID;
            var newPhoneIcon = "#PlaceHolder_NewPhoneIcon_" + recordID;

            $(phoneListPlaceHolder).removeClass('hidden');
            $(phoneListPlaceHolder).html(msg);
            $(newPhoneIcon).removeClass('hidden');
            $(phoneContainerPlaceHolder).html('');
            $(phoneContainerPlaceHolder).addClass('hidden');
        }
    });
}
function DeletePhoneNumber(phoneID, recordID, entityName) {
    $.modal.confirm('The phone number will be permanently removed; are you sure you want to delete this phone number?', function () {
        $.ajax({
            type: 'POST',
            url: '/Common/Phone/DeletePhoneNumber',
            data: { phoneID: phoneID },
            traditional: true,
            cache: false,
            success: function (msg) {
                ReloadPhoneList(recordID, entityName);
            }
        });
    }, function () {

    });
}

function SwitchViewToEditPhoneNumber(phoneID, recordID, entityName) {
    GetPhoneNumberDetails(phoneID, recordID, entityName);
}

function GetPhoneNumberDetails(phoneID, recordID, entityName) {
    $.ajax({
        url: '/Common/Phone/_GetPhoneNumberDetails',
        data: { recordID: recordID, entityName: entityName, phoneID: phoneID },
        success: function (msg) {

            var phoneListPlaceHolder = '#PlaceHolder_PhoneList_' + recordID;
            var phoneContainerPlaceHolder = '#PlaceHolder_PhoneContainer_' + recordID;
            var newPhoneIcon = "#PlaceHolder_NewPhoneIcon_" + recordID;

            $(phoneContainerPlaceHolder).removeClass('hidden');
            $(phoneListPlaceHolder).addClass('hidden');
            $(newPhoneIcon).addClass('hidden');
            $(phoneContainerPlaceHolder).html(msg);
        }
    });
}

function SwitchViewToPhoneCancel(recordID) {

    $('#frmPhoneContainer_' + recordID).validationEngine("hideAll");

    var phoneListPlaceHolder = '#PlaceHolder_PhoneList_' + recordID;
    var phoneContainerPlaceHolder = '#PlaceHolder_PhoneContainer_' + recordID;
    var newPhoneIcon = "#PlaceHolder_NewPhoneIcon_" + recordID;

    $(newPhoneIcon).removeClass('hidden');
    $(phoneListPlaceHolder).removeClass('hidden');
    $(phoneContainerPlaceHolder).addClass('hidden');
    $(phoneContainerPlaceHolder).html('');
}

function ValidateCombo(elementID) {
    var elementRef = $('#' + elementID).data('kendoComboBox').value();
    var elementTextBox = "input[name='" + elementID + "_input']";

    if ($.trim(elementRef).length == 0) {
        ShowValidationMessage($(elementTextBox), "This field is required.");
        return false;
    }
    else {
        HideValidationMessage($(elementTextBox));
    }

    return true;
}

function SavePhoneDetails(recordID, entityName, phoneID) {

    if ($('#frmPhoneContainer_' + recordID).validationEngine('validate') == false) {
        return false;
    }
    
    //Validate Phone Type
    if (!ValidateCombo('PhoneNumber_' + recordID + "_ddlPhoneType")) {
        return false;
    }

    var phoneTypeIDValue = $('#PhoneNumber_' + recordID + "_ddlPhoneType").data('kendoComboBox').value();
    var phoneNumber = GetPhoneNumberForDB('PhoneNumber_' + recordID);
    
    var postData = [];
    postData.push({ name: "PhoneID", value: phoneID });
    postData.push({ name: "EntityName", value: entityName });
    postData.push({ name: "RecordID", value: recordID });
    postData.push({ name: "PhoneTypeID", value: phoneTypeIDValue });
    postData.push({ name: "PhoneNumber", value: phoneNumber });
  
    $.ajax({
        type: 'POST',
        url: '/Common/Phone/SavePhoneDetails',
        data: postData,
        traditional: true,
        cache: false,
        success: function (msg) {
            ReloadPhoneList(recordID, entityName);
        }
    });
}