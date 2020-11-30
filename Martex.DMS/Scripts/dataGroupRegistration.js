
$(document).ready(function () {
    $(".uimultiselect").multiselect();
    $('#btnCancelDataGroup').die('click');
    $('#btnCancelDataGroup').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            HideValidationMessage($('input[name="OrganizationID_input"]'));
            $('#form-DataGroupRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            dataGroupDetailWindow.data('kendoWindow').close();
        }
    });

    $('#btnAddDataGroup').die('click');
    $('#btnAddDataGroup').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";

            if ($('#OrganizationID').data('kendoComboBox').value() == "") {
                ShowValidationMessage($('input[name="OrganizationID_input"]'), "Please select Organization");
                return false;
            }

            if ($("#spanDataGroupProgramValues").find("option:selected").length == 0) {
                openAlertMessage("At least one program must be selected.");
                return false;
            }
            if ($("#form-DataGroupRegistration").validationEngine('validate') == false) {
                return false;
            }

            var postData = $(this).parents('form').serializeArray();
            postData.push({ name: "DataGroup.OrganizationID", value: $('#OrganizationID').data('kendoComboBox').value() });

            var mode = $("#hdnfldMode").val();
            $.ajax('/DataGroups/Save', {
                type: 'POST',
                data: postData,
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('DataGroup successfully added!');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('DataGroup successfully updated!');
                        }
                        $('#form-DataGroupRegistration').validationEngine('hideAll');
                        dataGroupDetailWindow.data('kendoWindow').close();
                        $('#GrdDataGroups').data('kendoGrid').dataSource.read();
                    }
                }
            });
        }

        return false;
    });
});

