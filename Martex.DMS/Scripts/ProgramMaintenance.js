

//For Dirty Flag
$(function () {
    /// <summary>
    /// 
    /// </summary>
    $("input,textarea,select").change(function (e) {
        isdirty = true;
    });
    //    if ($("#hdnfldMode").val() == "view") {
    //        $("#ClientID").data("tComboBox").disable();
    //        $("#ParentProgramID").data("tComboBox").disable();
    //    }

    $("#form-ProgramMaintenance").validationEngine({ scroll: true });
    //For Closing the Pop Up
    $('#btnCancelProgram').die('click');
    $('#btnCancelProgram').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-ProgramMaintenance').validationEngine('hideAll');
            HideValidationMessage($('input[name="ClientID_input"]'));
            document.dialogResult = "CANCEL";
            programMaintenanceWindow.data('kendoWindow').close();
        }
    });

    //For Add button
    $('#btnAddProgram').die('click');
    $('#btnAddProgram').live('click', function (e) {


        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            if ($('#ClientID').data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="ClientID_input"]'), "Please select Client");
                return false;
            }
            else {
                HideValidationMessage($('input[name="ClientID_input"]'));
            }
            if ($("#form-ProgramMaintenance").validationEngine('validate') == false) {
                return false;
            }


            var postData = $(this).parents('form').serializeArray();
            var mode = $("#hdnfldMode").val();
            $.ajax('/Admin/ProgramMaintenance/Save', {
                type: 'POST',
                data: postData,
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('Program successfully added.');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('Program successfully updated.');
                        }
                        programMaintenanceWindow.data('kendoWindow').close();
                        $('#GrdProgramMaintenance').data('kendoGrid').dataSource.read();
                    }
                }
            });
        }

        return false;
    })


});

