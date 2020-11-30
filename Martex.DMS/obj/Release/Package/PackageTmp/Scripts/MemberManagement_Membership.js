
function GetComboValue(comboName) {
    return $('#' + comboName).data('kendoComboBox').value();
}


// Methods Related to Membership Information
function SaveMembershipInfoSection(membershipID) {
    var IsMembershipInfoSectionValid = true;
    var Combo_Membership_Info_Program = 'ProgramID_' + membershipID;
    if ($('#frmMembershipInfoSection_' + membershipID).validationEngine("validate") == false) {
        IsMembershipInfoSectionValid = false;
    }

    if (!ValidateCombo(Combo_Membership_Info_Program)) {
        IsMembershipInfoSectionValid = false;
    }
    if (IsMembershipInfoSectionValid) {
        var Data_Membership_Info = $('#frmMembershipInfoSection_' + membershipID).serializeArray();
        Data_Membership_Info.push({ name: "ProgramID", value: GetComboValue(Combo_Membership_Info_Program) });
        Data_Membership_Info.push({ name: "PrefixName", value: $('#PrefixID_' + membershipID).data('kendoComboBox').text() });
        Data_Membership_Info.push({ name: "SuffixName", value: $('#SuffixID_' + membershipID).data('kendoComboBox').text() });
        $.ajax({
            type: 'POST',
            url: '/MemberManagement/Member/SaveMembershipInfoDetails',
            data: Data_Membership_Info,
            success: function (msg) {
                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                CleanMyContainer('frmMemberContainerForDirtyFlag_' + membershipID);
                //Refresh the page 
                $('#MemberManagementMembershipTabs_' + membershipID).tabs('load', 0);
            }
        });
    }
    return false;
}

function CancelMembershipInfoSection(membershipID) {
    if (IsMyContainerDirty('frmMemberContainerForDirtyFlag_' + membershipID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            //Hide Validation Message
            $('#frmMembershipInfoSection_' + membershipID).validationEngine("hideAll");
            // Do Nothing 
            CleanMyContainer('frmMemberContainerForDirtyFlag_' + membershipID);
            //Refresh the page 
            $('#MemberManagementMembershipTabs_' + membershipID).tabs('load', 0);

        }, function () {
            // Do Nothing
        });
    }
}

// for Member Section

function CancelMemberInfoSection(membershipID, memberID) {
    if (IsMyContainerDirty('frmMemberContainerForDirtyFlag_' + membershipID)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            //Hide Validation Message
            $('#frmMemberInfoSection_' + memberID).validationEngine("hideAll");
            // Do Nothing 
            CleanMyContainer('frmMemberContainerForDirtyFlag_' + membershipID);
            //Refresh the page 
            $('#MemberManagementMemberTabs_' + memberID).tabs('load', 0);

        }, function () {
            // Do Nothing
        });
    }
}

// Methods Related to Member Information
function SaveMemberInfoSection(membershipID, memberID) {
    var IsMemberInfoSectionValid = true;
    var Combo_Member_Info_Program = 'ProgramID_' + memberID;
    if ($('#frmMemberInfoSection_' + memberID).validationEngine("validate") == false) {
        IsMemberInfoSectionValid = false;
    }

    if (!ValidateCombo(Combo_Member_Info_Program)) {
        IsMemberInfoSectionValid = false;
    }
    if (IsMemberInfoSectionValid) {
        var Data_Member_Info = $('#frmMemberInfoSection_' + memberID).serializeArray();
        Data_Member_Info.push({ name: "ProgramID", value: GetComboValue(Combo_Member_Info_Program) });
        Data_Member_Info.push({ name: "PrefixName", value: $('#PrefixID_' + memberID).data('kendoComboBox').text() });
        Data_Member_Info.push({ name: "SuffixName", value: $('#SuffixID_' + memberID).data('kendoComboBox').text() });
        $.ajax({
            type: 'POST',
            url: '/MemberManagement/Member/SaveMemberInfoDetails',
            data: Data_Member_Info,
            success: function (msg) {
                // Once the values save to DB Set page to No Dirty and Hide the Buttons
                CleanMyContainer('frmMemberContainerForDirtyFlag_' + membershipID);
                //Refresh the page 
                $('#MemberManagementMemberTabs_' + memberID).tabs('load', 0);
            }
        });
    }
    return false;
}