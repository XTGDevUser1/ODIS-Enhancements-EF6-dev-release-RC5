

//For Dirty Flag
$(function () {
    /// <summary>
    /// 
    /// </summary>
    $("input,textarea,select").change(function (e) {
        isdirty = true;
    });


    $("#form-PhoneSystemConfiguration").validationEngine({ scroll: true });
    //For Closing the Pop Up
    $('#btnCancelPhoneConfiguration').die('click');
    $('#btnCancelPhoneConfiguration').live('click', function (e) {
    
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-PhoneSystemConfiguration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            phoneSystemConfigurationDetailWindow.data('kendoWindow').close();
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
            if ($("#ProgramID").data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="ProgramID_input"]'), "Please select Program");
                return false;
            }
            else {
                HideValidationMessage($('input[name="ProgramID_input"]'));
            }
            if ($("#IVRScriptID").data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="IVRScriptID_input"]'), "Please select IVRScript");
                return false;
            }
            else {
                HideValidationMessage($('input[name="IVRScriptID_input"]'));
            }
            if ($("#SkillsetID").data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="SkillsetID_input"]'), "Please select Skillset");
                return false;
            }
            else {
                HideValidationMessage($('input[name="SkillsetID_input"]'));
            }
            if ($("#InboundPhoneCompanyID").data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="InboundPhoneCompanyID_input"]'), "Please select InboundPhoneCompany");
                return false;
            }
            else {
                HideValidationMessage($('input[name="InboundPhoneCompanyID_input"]'));
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
                        phoneSystemConfigurationDetailWindow.data('kendoWindow').close();
                        $('#GrdPhoneSystemConfiguration').data('kendoGrid').dataSource.read();
                    }
                }
            });
        }

        return false;
    })


});

