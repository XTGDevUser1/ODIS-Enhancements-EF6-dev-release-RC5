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
            memberWindow.data('kendoWindow').close();
            CleanMyContainer("form-Member");
            //            searchMemberPopUp.data('kendoWindow').close();
            //            queueDetailWindow.data('kendoWindow').close();
        }
    });


    //For Add button
    $('#btnAddMember').die('click');
    $('#btnAddMember').live('click', function (e) {
        if (!e.isDefaultPrevented()) {
            e.preventDefault();
            var $form = $("#form-Member");

            if ($form.validationEngine('validate') == false) {
                return false;
            }

            var memberModel = form2object("form-Member"); // Build an object from the form.
            memberModel["PhoneNumber"] = GetPhoneNumberForDB('PhoneNumber');
            memberModel["PhoneType"] = $("#PhoneNumber_ddlPhoneType").val();

            // If state is not selected then alert the user.
            //            var stateField = $('input[name="State_input"]');
            //            if ($.trim($('#State').data("kendoComboBox").value()).length == 0) {
            //                ShowValidationMessage(stateField, "Please select a state");
            //                $("html").scrollTop(0);
            //                return false;
            //            }
            //            else {
            //                HideValidationMessage(stateField);
            //            }

            //            // If state is not selected then alert the user.
            //            var CountryField = $('input[name="Country_input"]');
            //            if ($.trim($('#Country').data("kendoComboBox").value()).length == 0) {
            //                ShowValidationMessage(CountryField, "Please select a Country");
            //                $("html").scrollTop(0);
            //                return false;
            //            }
            //            else {
            //                HideValidationMessage(CountryField);
            //            }
            var programField = $('input[name="ProgramID_input"]');
            if ($.trim($('#ProgramID').data("kendoComboBox").value()).length == 0) {
                ShowValidationMessage(programField, "Please select a Program");

                $("html").scrollTop(0);
                return false;
            }
            else {
                HideValidationMessage(programField);
            }

            var errorsFound = false;
            // Check for fields to validated.
            if (fieldsForValidation == null) {
                openAlertMessage("Unable to get the fields to be validated for the selected program!");
                return false;
            }

            var $field;
            for (var i = 0, l = fieldsForValidation.length; i < l; i++) {
                switch (fieldsForValidation[i].Name.toLowerCase()) {


                    case 'requireaddress1':
                        $field = $("#AddressLine1");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requireaddress2':
                        $field = $("#AddressLine2");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requireaddress3':
                        $field = $("#AddressLine3");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requirecity':
                        $field = $("#City");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requirecountry':
                        $field = $("#Country").data("kendoComboBox");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="Country_input"]'), "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requireeffectivedate':
                        $field = $("#EffectiveDate").data("kendoDatePicker");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="EffectiveDate"]'), "* This field is required");
                            errorsFound = true;
                        }
                        break;
                    case 'requireemail':
                        $field = $("#Email");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requireexpirationdate':
                        $field = $("#ExpirationDate").data("kendoDatePicker");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="ExpirationDate"]'), "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requirefirstname':
                        $field = $form.find("#FirstName");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requirelastname':
                        $field = $form.find("#LastName");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requiremiddlename':
                        $field = $("#MiddleName");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requirephone':
                        $field = $("#PhoneNumber_txtPhoneNumber");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }

                        break;
                    case 'requireprefix':
                        $field = $("#Prefix").data("kendoComboBox");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="Prefix_input"]'), "* This field is required");
                            errorsFound = true;
                        }
                        break;
                    case 'requirezip':
                        $field = $("#PostalCode");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.val()).length == 0) {
                            ShowValidationMessage($field, "* This field is required");
                            errorsFound = true;
                        }
                        break;
                    case 'requirestate':
                        $field = $("#State").data("kendoComboBox");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="State_input"]'), "* This field is required");
                            errorsFound = true;
                        }
                        break;
                    case 'requiresuffix':
                        $field = $("#Suffix").data("kendoComboBox");
                        if (fieldsForValidation[i].Value.toLowerCase() == "yes" && $.trim($field.value()).length == 0) {
                            ShowValidationMessage($('input[name="Suffix_input"]'), "* This field is required");
                            errorsFound = true;
                        }
                        break;
                }
            }


            // Expiration date check - should be greater than effective date.
            var expirationDate = $("#ExpirationDate").data("kendoDatePicker").value();
            var effectiveDate = $("#EffectiveDate").data("kendoDatePicker").value();

            if (!$("#divEffectiveDate").is(":hidden")) {
                if (expirationDate != null && effectiveDate != null && expirationDate < effectiveDate) {
                    ShowValidationMessage($('input[name="ExpirationDate"]'), "Expiration Date should be greater than Effective Date");
                    errorsFound = true;
                }
            }

            if (typeof (validateMemberRegisterDynamicFields) != "undefined") {
                var isFormValid = validateMemberRegisterDynamicFields();
                if (!isFormValid) {
                    errorsFound = true;
                }
            }


            if (!errorsFound) {

                ClearValidationMessages();
               
                   if (typeof (getMemberRegisterDynamicFieldsValues) != "undefined") {

                    var dynamicMemeberDataElementsArray = [];
                    var dynamicFields = getMemberRegisterDynamicFieldsValues();

                    for(var i = 0, l = dynamicFields.length; i < l; i++) {
                        dynamicMemeberDataElementsArray.push({"Key": dynamicFields[i].name, "Value": dynamicFields[i].value});
                    }

                    memberModel["DynamicDataElements"]= dynamicMemeberDataElementsArray;
                }

                var postData = JSON.stringify(memberModel);

                $.ajax('/Application/Member/Save', {
                    type: 'POST',
                    traditional: true,
                    cache: false,
                    dataType: 'json',
                    contentType: 'application/json',
                    data: postData,
                    async: false,
                    success: function (msg) {
                        //Success Code
                        if (msg.Status == "Success") {
                            document.dialogResult = "OK";
                            if ($('#MemberID').length > 0) {

                                $('#MemberID').val(msg.Data.MemberID);
                            }
                            CleanMyContainer("form-Member");
                            memberWindow.data('kendoWindow').close();
                            
                            // TFS : 1392
                            if (typeof (msg.Data.MemberID) != "undefined" && msg.Data.MemberID != 0 && typeof (msg.Data.MembershipID) != "undefined" && msg.Data.MembershipID != 0) {

                                $('#MemberID').val(msg.Data.MemberID);
                                $('#MemberFoundFromMobile').val('false');
                                $('#GrdSearchMember').data('kendoGrid').dataSource.read();

                                $('#ddlCallType').data("kendoComboBox").value('2');
                                ShowMemberSearchPopUp(msg.Data.MemberID, msg.Data.MembershipID, "Member Details :: " + msg.Data.MemberID);
                            }
                            // END TFS :1392
                        }
                        else if (msg.Status == "BusinessRuleFail") {
                            var fieldsFailedValidation = msg.Data.MemberID;
                            var formattedMessage = "<table class='table simple-table'>";

                            for (var i = 0, l = fieldsFailedValidation.length; i < l; i++) {
                                formattedMessage += "<tr><td>" + fieldsFailedValidation[i] + "</td></tr>";
                            }

                            formattedMessage += "</table>";

                            openAlertMessage("The following fields failed validation : " + formattedMessage);
                        }
                    }
                });
            }
        }
        return false;
    });
});