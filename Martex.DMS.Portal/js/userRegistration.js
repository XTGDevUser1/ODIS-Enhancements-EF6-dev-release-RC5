


$(document).ready(function () {

    $(".uimultiselect").multiselect();


    $('#btnCancelUser').die('click');
    $('#btnCancelUser').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            $('#form-UserRegistration').validationEngine('hideAll');
            document.dialogResult = "CANCEL";
            userDetailWindow.data('tWindow').close();
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

            if ($("#OrganizationID").data("tComboBox").value() == '') {
                openAlertMessage("Please select organization.");
                return false;
            }

            if ($('#UserName').val().indexOf(" ") > 0) {
                openAlertMessage("User Name cannot contain spaces.");
                return false;
            }
            if ($("#spUserRoles").find("option:selected").length == 0) {
                openAlertMessage("Please select at least one role.");
                return false;
            }

            //            if ($("#spDataGroups").find("option:selected").length == 0) {
            //                openAlertMessage("Please select at least one Data Group.");
            //                return false;
            //            }
            
            var postData = $(this).parents('form').serializeArray();
            var mode = $("#hdnfldMode").val();
            //postData.push({ name: "mode", value: "add" });
            // This is where you may do your AJAX call, for instance:
            $.ajax('/Users/Save', {
                type: 'POST',
                data: postData,
                success: function (json) {
                    if (json.Status == "Success") {
                        if (mode == "add") {
                            openAlertMessage('User successfully added!');
                        }
                        else if (mode == "edit") {
                            openAlertMessage('User successfully updated!');
                        }
                        $('#form-UserRegistration').validationEngine('hideAll');
                        userDetailWindow.data('tWindow').close();
                        $('#GrdUsers').data('tGrid').ajaxRequest();
                        // Redirect the user to home page                        
                        //location = "/Home";
                        //setTimeout("window.location.href='/Home'", 1500);
                    }
                }

            });
        }

        return false;
    });
});

