function DeleteExcludedVendorForMembership(recordID, membershipID) {
    var message = "The vendor will be removed from the list; are you sure you want to remove this vendor?";
    $.modal.confirm(message, function () {
        $.ajax({
            type: 'POST',
            url: '/MemberManagement/Common/DeleteExcludedVendor',
            data: { recordID: recordID },
            success: function (msg) {
                ReloadExcludedVendorList(membershipID);
            }
        });
    }, function () {

    });
}

function ExcludedVendorMemberShipSwitchViewToEdit(membershipID) {

    $.ajax({
        url: '/MemberManagement/Common/GetExcludedVendor',
        data: { membershipID: membershipID },
        success: function (msg) {

            var excludedVendorListPlaceHolder = '#PlaceHolder_ExcludedVendorList_' + membershipID;
            var excludedVendorContainerPlaceHolder = '#PlaceHolder_ExcludedVendorContainer_' + membershipID;
            var newVendorIcon = "#PlaceHolder_NewVendorIcon_" + membershipID;
            $(excludedVendorListPlaceHolder).addClass('hidden');
            $(newVendorIcon).addClass('hidden');
            $(excludedVendorContainerPlaceHolder).removeClass('hidden');
            $(excludedVendorContainerPlaceHolder).html(msg);
        }
    });
}
function ExcludedVendorsSwitchViewToCancel(membershipID) {

    $('#form_ExcludedVendors_' + membershipID).validationEngine("hideAll");

    var excludedVendorListPlaceHolder = '#PlaceHolder_ExcludedVendorList_' + membershipID;
    var excludedVendorContainerPlaceHolder = '#PlaceHolder_ExcludedVendorContainer_' + membershipID;
    var newVendorIcon = "#PlaceHolder_NewVendorIcon_" + membershipID;

    $(excludedVendorContainerPlaceHolder).addClass('hidden');
    $(excludedVendorListPlaceHolder).removeClass('hidden');
    $(newVendorIcon).removeClass('hidden');
    $(excludedVendorContainerPlaceHolder).html('');
}
function ExcludedVendorsSaveExcludedVendor(membershipID) {
    var vendorID_Value = $("#EV_VendorID_" + membershipID).val();
    
    if (vendorID_Value == undefined || vendorID_Value == null || vendorID_Value == '' || vendorID_Value == "0") {
        $('#ExcludedVendorLookUP_' + membershipID).val('');
    }

    if ($('#form_ExcludedVendors_' + membershipID).validationEngine("validate") == true) {
        var postData = $('#form_ExcludedVendors_' + membershipID).serializeArray();
        $.ajax({
            type : 'POST',
            url: '/MemberManagement/Common/SaveExcludedVendor',
            data: postData,
            success: function (msg) {
                ReloadExcludedVendorList(membershipID);
            }
        });
    }
    return false;
}

function ClearExcludedVendorLookUP(membershipID) {
    $('#EV_VendorID_' + membershipID).val('');
    $('#EV_VendorNumber_' + membershipID).val('');
}

function ReloadExcludedVendorList(membershipID) {
    $.ajax({
        url: '/MemberManagement/Common/GetExcludedVendorList',
        type: 'GET',
        data: { membershipID: membershipID },
        success: function (msg) {

            var excludedVendorListPlaceHolder = '#PlaceHolder_ExcludedVendorList_' + membershipID;
            var excludedVendorContainerPlaceHolder = '#PlaceHolder_ExcludedVendorContainer_' + membershipID;
            var newVendorIcon = "#PlaceHolder_NewVendorIcon_" + membershipID;

            $(excludedVendorListPlaceHolder).removeClass('hidden');
            $(excludedVendorListPlaceHolder).html(msg);
            $(newVendorIcon).removeClass('hidden');
            $(excludedVendorContainerPlaceHolder).html('');
            $(excludedVendorContainerPlaceHolder).addClass('hidden');
        }
    });
}