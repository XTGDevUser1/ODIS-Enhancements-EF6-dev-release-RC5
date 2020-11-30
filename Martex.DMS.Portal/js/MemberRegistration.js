$(function () {

    //For Dirty Flag
    $("input,textarea,select").change(function (e) {
        isdirty = true;
    });

    //For Validation Engine
    $("#form-Member").validationEngine({ scroll: true });

    //For Closing the Pop Up
    $('#btnCancelMember').die('click');
    $('#btnCancelMember').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-Member').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            memberWindow.data('tWindow').close();
        }
    });

    //For Add button
    $('#btnAddMember').die('click');
    $('#btnAddMember').live('click', function (e) {

        if (!e.isDefaultPrevented()) {
            e.preventDefault();


            if ($("#form-Member").validationEngine('validate') == false) {
                return false;
            }

            var memberModel = form2object("form-Member"); // Build an object from the form.
            memberModel["PhoneNumber"] = GetPhoneNumberForDB('PhoneNumber');
            memberModel["PhoneType"] = $("#PhoneNumber_ddlPhoneType").val();

            // If state is not selected then alert the user.
            var stateField = $('#State-input');
            if ($.trim($('#State').data("tComboBox").value()).length == 0) {
                ShowValidationMessage(stateField, "Please select a state");
                $("html").scrollTop(0);
                return false;
            }
            else {
                HideValidationMessage(stateField);
            }

            // If state is not selected then alert the user.
            var CountryField = $('#Country-input');
            if ($.trim($('#Country').data("tComboBox").value()).length == 0) {
                ShowValidationMessage(CountryField, "Please select a Country");
                $("html").scrollTop(0);
                return false;
            }
            else {
                HideValidationMessage(CountryField);
            }
            //   debugger;
            var programField = $('#ProgramID-input');
            if ($.trim($('#ProgramID').data("tComboBox").value()).length == 0) {
               ShowValidationMessage(programField, "Please select a Program");
               
                $("html").scrollTop(0);
                return false;
            }
            else {
                HideValidationMessage(programField);
            }


            var postData = JSON.stringify(memberModel);
            $.ajax('/Member/Save', {
                type: 'POST',
                traditional: true,
                cache: false,
                dataType: 'json',
                contentType: 'application/json',
                data: postData,
                async: false,
                success: function (msg) {
                    //Success Code
                    document.dialogResult = "OK";
                    if ($('#MemberID').length > 0) {

                        $('#MemberID').val(msg.Data);
                    }
                    ClearDirtyFlag("popupcontainer");
                    memberWindow.data('tWindow').close();
                }
            });
        }
        return false;
    });
});