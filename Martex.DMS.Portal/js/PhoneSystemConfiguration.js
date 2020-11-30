

//For Dirty Flag
$(function () {
    $("input,textarea,select").change(function (e) {
        isdirty = true;
    });

    if ($("#hdnfldMode").val() == "view") {
        $("#ProgramID").data("tComboBox").disable();
        $("#IVRScriptID").data("tComboBox").disable();
        $("#InboundPhoneCompanyID").data("tComboBox").disable();
        $("#SkillsetID").data("tComboBox").disable();
    }



    $("#form-PhoneSystemConfiguration").validationEngine({ scroll: true });
    //For Closing the Pop Up
    $('#btnCancelPhoneConfiguration').die('click');
    $('#btnCancelPhoneConfiguration').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-PhoneSystemConfiguration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            phoneSystemConfigurationDetailWindow.data('tWindow').close();
        }
    });

    //For Add button
    $('#btnAddPhoneConfiguration').die('click');
    $('#btnAddPhoneConfiguration').live('click', function (e) {

        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            if ($("#form-PhoneSystemConfiguration").validationEngine('validate') == false) {
                return false;
            }
            if ($("#ProgramID").data("tComboBox").value() == "") {
                openAlertMessage("Please select Program");
                //$("#ProgramID").validationEngine('showPrompt', 'Please select Program', '', 'topRight', true);
                return false;
            }
            if ($("#IVRScriptID").data("tComboBox").value() == "") {
                openAlertMessage("Please select IVR Script");
                return false;
            }
            var postData = $(this).parents('form').serializeArray();
            var mode = $("#hdnfldMode").val();
            $.ajax('/PhoneSystemConfiguration/Save', {
                type: 'POST',
                data: postData,
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('Phone System Configuration successfully added.');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('Phone System Configuration successfully updated.');
                        }
                        //  $('#form-OrganizationRegistration').validationEngine('hideAll');
                        phoneSystemConfigurationDetailWindow.data('tWindow').close();
                        $('#GrdPhoneSystemConfiguration').data('tGrid').ajaxRequest();
                    } 
                }
            });
        }

        return false;
    })


});

