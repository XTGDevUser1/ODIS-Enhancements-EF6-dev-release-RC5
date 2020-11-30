
$(document).ready(function () {
    $(".uimultiselect").multiselect();
    $('#btnCancelClient').die('click');
    $('#btnCancelClient').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-ClientRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            clientDetailWindow.data('tWindow').close();
        }
    });

    $('#btnAddClient').die('click');
    $('#btnAddClient').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            if ($("#spOrganizationClients").find("option:selected").length == 0) {
                openAlertMessage("Please select at least one organization");
                return false;
            }

            if ($("#form-ClientRegistration").validationEngine('validate') == false) {
                return false;
            }
            
            // var postData = $(this).parents('form').serializeArray();
            var clientModel = form2object("form-ClientRegistration");
            var grid = $("#GrdAddress").data("tGrid");
            var addressesGrid = new AddressesGrid(grid);
            var mode = $("#hdnfldMode").val();
            //Note: For themed checkboxes, when using form2object, the following is the way to retrieve the checked state of a checkbox.
            clientModel["isActive"] = $("#isActive").is(":checked");
            clientModel["InsertedAddresses"] = addressesGrid.getInsertedAddresses();
            clientModel["UpdatedAddresses"] = addressesGrid.getUpdatedAddresses();
            clientModel["DeletedAddresses"] = addressesGrid.getDeletedAddresses();

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
                        clientDetailWindow.data('tWindow').close();
                        $('#GrdClients').data('tGrid').ajaxRequest();
                    }
                }
            });
        }

        return false;
    });
});

