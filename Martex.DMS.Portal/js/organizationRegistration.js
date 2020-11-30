

$(document).ready(function () {
    $(".uimultiselect").multiselect();
    $('#btnCancelOrganization').die('click');
    $('#btnCancelOrganization').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-OrganizationRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            organizationDetailWindow.data('tWindow').close();
        }
    });

    $('#btnAddOrganization').die('click');
    $('#btnAddOrganization').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            if ($("#spOrganizationRoles").find("option:selected").length == 0) {
                openAlertMessage("Please select at least one role");
                return false;
            }
            if ($("#spOrganizationClients").find("option:selected").length == 0) {
                openAlertMessage("Please select at least one client");
                return false;
            }

            if ($("#form-OrganizationRegistration").validationEngine('validate') == false) {
                return false;
            }
            var parentOrganizationId = $("#Parent_OrganizationID").data("tComboBox").value();

            if (parentOrganizationId == "") {
                //openAlertMessage("Please select Parent Organization");
                $("#Parent_OrganizationID-input").validationEngine('showPrompt', 'Parent Organization is required.', '', 'topRight', true);
                return false;
            }

            var orgModel = form2object("form-OrganizationRegistration");
            var grid = $("#GrdAddress").data("tGrid");
            var gridAddresses = new AddressesGrid(grid);
            var mode = $("#hdnfldMode").val();

            orgModel["InsertedAddresses"] = gridAddresses.getInsertedAddresses();
            orgModel["UpdatedAddresses"] = gridAddresses.getUpdatedAddresses();
            orgModel["DeletedAddresses"] = gridAddresses.getDeletedAddresses();

//            grid = $("#GrdPhone").data("tGrid");
//            var gridPhone = new PhoneGrid(grid);

//            orgModel["InsertedPhoneDetails"] = gridPhone.getInsertedPhoneDetails();
//            orgModel["UpdatedPhoneDetails"] = gridPhone.getUpdatedPhoneDetails();
//            orgModel["DeletedPhoneDetails"] = gridPhone.getDeletedPhoneDetails();

            orgModel["ParentOrganizationID"] = parentOrganizationId;
            orgModel["mode"] = mode;

            $.ajax('/Organizations/Save', {
                type: 'POST',
                dataType: 'json',
                contentType: 'application/json',
                data: JSON.stringify(orgModel),
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('Organization successfully added!');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('Organization successfully updated!');
                        }
                        $('#form-OrganizationRegistration').validationEngine('hideAll');
                        organizationDetailWindow.data('tWindow').close();
                        $('#GrdOrganizations').data('tGrid').ajaxRequest();
                    }
                }
            });
        }

        return false;
    });
});

