


$(document).ready(function () {

    $(".uimultiselect").multiselect();


    $('#btnCancelUser').die('click');
    $('#btnCancelUser').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-UserRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            userDetailWindow.data('kendoWindow').close();
        }
    });
    $('#btnAddUser').die('click');
    $('#btnAddUser').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            document.dialogResult = "OK";
            // Fire the validators on the themed multi-select controls and present validation error messages
            if ($("#form-UserRegistration").validationEngine('validate') == false) {
                return false;
            }

            if ($('#UserName').val().indexOf(" ") > 0) {
                openAlertMessage("User Name cannot contain spaces.");
                return false;
            }
//            if ($("#spUserRoles").find("option:selected").length == 0) {
//                openAlertMessage("Please select at least one role.");
//                return false;
//            }

            var postData = $(this).parents('form').serializeArray();
            var mode = $("#hdnfldMode").val();

            //            $.ajax({

            //                type: 'POST',
            //                url: '@Url.Action("Save", "Home",new {area = "Users"})',
            $.ajax('/Users/Home/Save', {
                type: 'POST',
                data: postData,
                success: function (json) {
                    if (json.Status == "Success") {
                        CleanMyContainer('form-UserRegistration');
                        if (mode == "add") {
                            openAlertMessage('User successfully added!');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('User successfully updated!');
                        }
                        $('#form-UserRegistration').validationEngine('hideAll');
                        userDetailWindow.data('kendoWindow').close();
                        $('#GrdUsers').data('kendoGrid').dataSource.read();
                    }
                }

            });
        }

        return false;
    });
});

