
$(document).ready(function () {
    $(".uimultiselect").multiselect();
    $('#btnCancelDataGroup').die('click');
    $('#btnCancelDataGroup').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-DataGroupRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            dataGroupDetailWindow.data('tWindow').close();
        }
    });

    $('#btnAddDataGroup').die('click');
    $('#btnAddDataGroup').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";

            if ($("#OrganizationID").data("tComboBox").value() == "") {
                openAlertMessage("Please select Organization");
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
            postData.push({ name: "DataGroup.OrganizationID", value: $("#OrganizationID").data("tComboBox").value() });
            
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
                        dataGroupDetailWindow.data('tWindow').close();
                        $('#GrdDataGroups').data('tGrid').ajaxRequest();
                    }
                }
            });
        }

        return false;
    });
});

