

    //For Dirty Flag
    $(function () {
        $("input,textarea,select").change(function (e) {
            isdirty = true;
        });
        if ($("#hdnfldMode").val() == "view") {
            $("#ClientID").data("tComboBox").disable();
            $("#ParentProgramID").data("tComboBox").disable();
        }

        $("#form-ProgramMaintenance").validationEngine({ scroll: true });
    //For Closing the Pop Up
        $('#btnCancelProgram').die('click');
        $('#btnCancelProgram').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-ProgramMaintenance').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            programMaintenanceWindow.data('tWindow').close();
        }
    });

    //For Add button
    $('#btnAddProgram').die('click');
    $('#btnAddProgram').live('click', function (e) {

        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            if ($("#form-ProgramMaintenance").validationEngine('validate') == false) {
                return false;
            }
            if ($("#ClientID").data("tComboBox").value() == "") {
                openAlertMessage("Please select Client");
                //$("#ClientID").validationEngine('showPrompt', 'Please select Client', '', 'topRight', true);
                return false;
            }
            var postData = $(this).parents('form').serializeArray();
            var mode = $("#hdnfldMode").val();
            $.ajax('/ProgramMaintenance/Save', {
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
                        programMaintenanceWindow.data('tWindow').close();
                        $('#GrdProgramMaintenance').data('tGrid').ajaxRequest();
                    } 
                }
            });
        }

        return false;
    })


});

