
$(document).ready(function () {

    $(".uimultiselect").multiselect();

    $('#btnCancelClient').die('click');
    $('#btnCancelClient').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-ClientRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            clientDetailWindow.data('kendoWindow').close();
        }
    });

    $('#btnAddClient').die('click');
    $('#btnAddClient').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
           
            if ($("#form-ClientRegistration").validationEngine('validate') == false) {
                return false;
            }

            var multiselect = $("#ClientOrganizationsValues").data("kendoMultiSelect");
            if (multiselect != undefined && multiselect.value().length == 0) {
                openAlertMessage("Please select at least one organization");
                return false;
            }

            var clientModel = form2object("form-ClientRegistration");
            var mode = $("#hdnfldMode").val();
            //Note: For themed checkboxes, when using form2object, the following is the way to retrieve the checked state of a checkbox.
            clientModel["isActive"] = $("#isActive").is(":checked");
            clientModel["mode"] = mode;


            // postData
            $.ajax('/Clients/Save', {
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(clientModel),
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('Client successfully added!');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('Client successfully updated!');
                        }
                        $('#form-ClientRegistration').validationEngine('hideAll');
                        clientDetailWindow.data('kendoWindow').close();
                        $('#GrdClients').data('kendoGrid').dataSource.read();
                    }
                }
            });
        }

        return false;
    });
});

