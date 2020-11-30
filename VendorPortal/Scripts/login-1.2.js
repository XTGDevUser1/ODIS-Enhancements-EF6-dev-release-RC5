function openAlertMessage(alertMessage, fnCloseCallback) {
    /// <summary>
    /// Custom Alert modal window
    /// </summary>
    /// <param name="alertMessage">Message</param>
    /// <param name="fnCloseCallback">Callback that should be invoked while closing the window.</param>
    $.modal.alert(alertMessage, {
        buttons: {
            'OK': {
                classes: 'huge blue-gradient glossy full-width',
                click: function (win) { win.closeModal(); }
            }
        },
        onClose: function () { if (fnCloseCallback != null) { fnCloseCallback(); } return true; }
    });
}


/*
* How do I hook my login script to these?
* --------------------------------------
*
* These scripts are meant to be non-obtrusive: if the user has disabled javascript or if an error occurs, the forms
* works fine without ajax.
*
* The only part you need to edit are the scripts between the EDIT THIS SECTION tags, which do inputs validation and
* send data to server. For instance, you may keep the validation and add an AJAX call to the server with the user
* input, then redirect to the dashboard or display an error depending on server return.
*
* Or if you don't trust AJAX calls, just remove the event.preventDefault() part and let the form be submitted.
*/

$(document).ready(function () {

    /*
    * JS login effect
    * This script will enable effects for the login page
    */
    // Elements
    var doc = $('html').addClass('js-login'),
				container = $('.container'),
				formWrapper = $('.frmWrapper'),
				formBlock = $('#form-block'),
				formViewport = formWrapper, //$('#form-viewport'),
    forms = formViewport.children('form'),

    // Doors
    //				topDoor = $('<div id="top-door" class="form-door"><div></div></div>').appendTo(formViewport),
    //				botDoor = $('<div id="bot-door" class="form-door"><div></div></div>').appendTo(formViewport),
    //				doors = topDoor.add(botDoor),

    // Switch
				formSwitch = $('<span/>').appendTo(formBlock).children(),

    // Current form
				hash = (document.location.hash.length > 1) ? document.location.hash.substring(1) : false,

    // If layout is centered
				centered,

    // Store current form
				currentForm,

    // Animation interval
				animInt,

    // Work vars
				maxHeight = false,
				blocHeight;

    /******* EDIT THIS SECTION *******/
    //KB: Initialize Validation Engine
    forms.each(function () { $(this).validationEngine({ promptPosition: "centerRight" }); });


    /*
    * Login
    * These functions will handle the login process through AJAX
    */
    $('#form-login').submit(function (event) {

        if ($("#form-login").validationEngine('validate') == false) {
            return false;
        }
        // Values
        var username = $.trim($('#login_username').val()),
			password = $.trim($('#login_password').val());

        var returnUrl = $('#returnUrl').val();


        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Checking credentials...');

        // Stop normal behavior
        event.preventDefault();
        var loginmodel = {
            UserName: username,
            Password: password,
            ReturnUrl: returnUrl

        };

        // This is where you may do your AJAX call, for instance:
        $.ajax('/Account/JsonLogOn', {
            type: 'POST',
            data: loginmodel,
            success: function (json) {

                if (json.success) {
                    // Redirect the user to home page

                    location.href = json.redirect || "/";
                    //setTimeout("window.location.href=location", 1500);
                } else if (json.errors) {
                    // Remove previous messages
                    formWrapper.clearMessages();
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    displayError(items);
                }
            },
            error: function (err) {

                if (err.status == 403) {
                    Handle403(err);
                    return false;
                }
                // Remove previous messages
                formWrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, 1000);
                }
                else {
                    displayError(err, 1000);
                }
            }
        });

        return false;
        //        // Simulate server-side check
        //        setTimeout(function () {
        //            document.location.href = './'
        //        }, 2000);

    });

    /*
    * Password recovery
    */
    $('#form-password').submit(function (event) {

        if ($('#form-password').validationEngine('validate') == false) {
            return false;
        }
        // Values
        var userName = $.trim($('#forgotpassword_username').val());

        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Looking up Username...');

        // Stop normal behavior
        event.preventDefault();

        /*
        * This is where you may do your AJAX call
        */

        $.ajax('/ForgotPassword/JsonForgotPassword', {
            type: 'POST',
            data: { username: userName },
            success: function (json) {

                if (json.success) {
                    formWrapper.clearMessages();
                    //notify('Forgot password', 'Password sent to your email', {
                    //  autoClose: false,
                    //  delay: 1500
                    //});
                    displaySuccess("Password reset link sent to your email");
                } else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    formWrapper.clearMessages();
                    displayError(items);
                }
            },
            error: function (err) {
                formWrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, 1000);
                }
                else {
                    displayError(err, 1000);
                }
            }
        });



    });

    /*
    * Register
    */
    $('#form-register').submit(function (event) {

        if ($("#form-register").validationEngine('validate') == false) {
            return false;
        }

        // Values
        var username = $.trim($('#register_username').val()),
			email = $.trim($('#register_email').val()),
			password = $.trim($('#register_password').val()),
			confirmpassword = $.trim($('#register_confirmpassword').val());

        // Remove previous messages
        formWrapper.clearMessages();



        // Show progress
        displayLoading('Registering...');

        // Stop normal behavior
        event.preventDefault();

        /*
        * This is where you may do your AJAX call
        */

        var registerModel = {
            UserName: username,
            Email: email,
            Password: password,
            ConfirmPassword: confirmpassword
        };

        $.ajax('/Account/JsonRegister', {
            type: 'POST',
            data: registerModel,
            success: function (json) {

                if (json.success) {
                    // Redirect the user to home page                        
                    location = "/Home";
                    displaySuccess("User Created Successfully");
                    //                    notify('Registration', 'User created successfully', {
                    //                        autoClose: false,
                    //                        delay: 1500,
                    //                        icon: 'img/demo/icon.png'
                    //                    });
                    setTimeout("window.location.href='/Home'", 1500);
                } else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    displayError(items);
                }
            },
            error: function (err) {
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, 1000);
                }
                else {
                    displayError(err, 1000);
                }
            }
        });

    });


    /* Transition Login related event handlers */
    /*
    * Login
    * These functions will handle the login process through AJAX
    */
    $('#btnTransitionLoginVerify').click(function (event) {

        $('#AccountTransitionRegisteredMessage').addClass("hidden");

        if ($("#form_login_transition").validationEngine('validate') == false) {
            return false;
        }
        // Values
        var username = $.trim($('#login_username').val()),
			password = $.trim($('#login_password').val());

        var returnUrl = $('#returnUrl').val();


        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Checking credentials...');

        // Stop normal behavior
        event.preventDefault();
        var loginmodel = {
            UserName: username,
            Password: password,
            ReturnUrl: returnUrl

        };

        // This is where you may do your AJAX call, for instance:
        $.ajax('/TransitionRegister/JsonTransitionVerify', {
            type: 'POST',
            data: loginmodel,
            success: function (json) {

                if (json.registered) {
                    formWrapper.clearMessages();
                    $('#AccountTransitionRegisteredMessage').removeClass("hidden");
                }
                else if (json.success) {
                    // Redirect the user to register page
                    formWrapper.clearMessages();
                    $('#VendorID').val(json.VendorID);
                    $('#form_login_transition').submit();
                    //setTimeout("window.location.href=location", 1500);
                } else if (json.errors) {
                    // Remove previous messages
                    formWrapper.clearMessages();
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    displayError(items);
                }
            },
            error: function (err) {
                if (err.status == 403) {
                    Handle403(err);
                    return false;
                }
                // Remove previous messages
                formWrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, 1000);
                }
                else {
                    displayError(err, 1000);
                }
            }
        });

        return false;
        //        // Simulate server-side check
        //        setTimeout(function () {
        //            document.location.href = './'
        //        }, 2000);

    });


    $('#btnRegisterVendorTransition').live("click", function (event) {

        // Stop normal behavior
        event.preventDefault();

        if ($("#form_registerVendor").validationEngine('validate') == false) {
            return false;
        }

        // Values
        var username = $.trim($('#register_username').val()),
			email = $.trim($('#register_email').val()),
			password = $.trim($('#register_password').val()),
			confirmpassword = $.trim($('#register_confirmpassword').val()),
            vendorID = $("#VendorID").val(),
            firstName = $("#register_firstname").val(),
            lastName = $("#register_lastname").val();
        // Remove previous messages
        formWrapper.clearMessages();


        // Show progress
        displayLoading('Registering...');

        var registerModel = {
            UserName: username,
            Email: email,
            Password: password,
            ConfirmPassword: confirmpassword,
            VendorID: vendorID,
            FirstName: firstName,
            LastName: lastName
        };

        $.ajax('/TransitionRegister/SaveVendorTransition', {
            type: 'POST',
            data: registerModel,
            success: function (json) {

                if (json.Status == "Success") {
                    // Redirect the user to home page                        
                    //location = "/Home";
                    formWrapper.clearMessages();
                    $('#form_registerVendor').submit();
                } else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    formWrapper.clearMessages();
                    displayError(items);
                }
            },
            error: function (err) {
                formWrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, 1000);
                }
                else {
                    displayError(err, 1000);
                }
            }
        });

    });
    /* 
    * Vendor Identity verification
    */

    $('#btnVerify').click(function (event) {

        var wrapper = $(".divRegistrationForm");
        if ($("#form-verify").validationEngine('validate') == false) {
            return false;
        }
        // Values
        var vendorNumber = $.trim($('#VendorNumber').val()),
		phoneNumber = GetPhoneNumberForDB('OfficePhone');;

        // Remove previous messages
        wrapper.clearMessages();

        // Show progress
        displayLoading('Verifying ...', wrapper);

        // Stop normal behavior
        event.preventDefault();
        var vendorIdentity = {
            VendorNumber: vendorNumber,
            PhoneNumber: phoneNumber
        };

        // This is where you may do your AJAX call, for instance:
        $.ajax('/Register/Index', {
            type: 'POST',
            data: vendorIdentity,
            cache: false,
            success: function (json) {
                // Remove previous messages

                if (json.Status == "NotFound") {
                    wrapper.clearMessages();
                    displayError("Information not found, please try again or call Vendor Services at 800-285-4977", wrapper);
                }
                else if (json.Status == "Registered") {
                    wrapper.clearMessages();
                    displayError("Already registered.  Go to login screen and login or use the forgot username/password feature", wrapper);
                    //displayError("Your account has already been activated.  Please go to the Login page and login.  If you have forgotten your password you can request it be sent to you from the Login page.");
                }
                else if (json.Status == "NotRegistered") {
                    // Redirect the url to Register page.
                    $.ajax('/Register/RegisterVendor', {
                        type: 'GET',
                        cache: false,
                        data: { id: json.Data.vendorID },
                        success: function (response) {
                            wrapper.clearMessages();
                            formViewport.css("height", "550px");
                            formViewport.html(response);

                            $(".instructions").hide();
                            setTimeout(function () {
                                container.css("margin-top", "0px");
                                container.css("top", "0px");
                            }, 500);
                        },
                        error: function (err) {
                            //TODO: Handle error
                        }
                    });


                }
                else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    wrapper.clearMessages();
                    displayError(items, wrapper);
                }
            },
            error: function (err) {
                if (err.status == 403) {
                    Handle403(err);
                    return false;
                }
                // Remove previous messages
                wrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, wrapper);
                }
                else {
                    displayError(err, wrapper);
                }
            }
        });
        return false;
    });

    /*
    * Register
    */
    $('#btnRegisterVendor').live("click", function (event) {

        var wrapper = $(".divRegisterDetailsForm");
        // Stop normal behavior
        event.preventDefault();

        if ($("#form-registerVendor").validationEngine('validate') == false) {
            return false;
        }

        // Values
        var username = $.trim($('#register_username').val()),
			email = $.trim($('#register_email').val()),
			password = $.trim($('#register_password').val()),
			confirmpassword = $.trim($('#register_confirmpassword').val()),
            vendorID = $("#hdnVendorID").val(),
            firstName = $("#register_firstname").val(),
            lastName = $("#register_lastname").val();
        // Remove previous messages
        wrapper.clearMessages();



        // Show progress
        displayLoading('Registering...', wrapper);

        var registerModel = {
            UserName: username,
            Email: email,
            Password: password,
            ConfirmPassword: confirmpassword,
            VendorID: vendorID,
            FirstName: firstName,
            LastName: lastName
        };

        $.ajax('/Register/RegisterVendor', {
            type: 'POST',
            data: registerModel,
            success: function (json) {

                if (json.Status == "Success") {
                    // Redirect the user to home page                        
                    //location = "/Home";
                    wrapper.clearMessages();
                    //displaySuccess("An email has just been sent to you.  Please check this email and click on the <b>Account Confirmation</b> link in the email to complete the registration process", wrapper);
                    //                    notify('Registration', 'An email has just been sent to you.  Please check this email and click on the <b>Account Confirmation</b> link in the email to complete the registration process', {
                    //                        autoClose: false,
                    //                        delay: 1500

                    //                    });
                    //setTimeout("window.location.href='/Home'", 1500);
                    setTimeout("window.location.href='/Register/RegisterSuccess'", 1500);
                } else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    wrapper.clearMessages();
                    displayError(items, wrapper);
                }
            },
            error: function (err) {
                wrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, wrapper);
                }
                else {
                    displayError(err, wrapper);
                }
            }
        });

    });

    /*
    * Forgot Password
    */
    $("#btnChangePassOnForgotPass").click(function (e) {
        var $form = $("#frmChangePassOnForgotPass");

        var formData = $form.serializeArray();
        if ($form.validationEngine('validate') == false) {
            return false;
        }
        formData.push({ name: "UpdateChangePassVendorUser", value: true });
        formData.push({ name: "ChangePasswordModel.OldPassword", value: $('#passwordResetToken').val() }); //'@passwordResetToken'
        formData.push({ name: "ChangePasswordModel.UserName", value: $('#userName').val() }); //'@userName'
        formData.push({ name: "ChangePasswordModel.Email", value: $('#email').val() }); //value: '@email'

        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Updating Password...');
        $("#btnChangePassOnForgotPass").attr("disabled", "disabled");
        $.ajax('/Account/UpdatePassword', {
            type: 'POST',
            //traditional: true,
            data: formData,
            //cache: false,
            //async: true,
            //global: true,            
            success: function (msg) {
                formWrapper.clearMessages();
                if (msg.Status == "Success") {
                    formWrapper.clearMessages();
                    displaySuccess("Password has been updated. Redirecting to Login Page.");
                    setTimeout(function (e) {
                        window.location.href = '/Account/Login';
                    }, 500);
                }
                else if (msg.Status == "Failure") {
                    $("#btnChangePassOnForgotPass").removeAttr("disabled");
                    displayError(msg.Data, 1000);
                    //openAlertMessage(msg.Data);
                }
            },
            error: function (err) {
                wrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, wrapper);
                }
                else {
                    displayError(err, wrapper);
                }
            }
        } // end of ajax options
                    );

        return false;
    });

    /******* END OF EDIT SECTION *******/

    /*
    * Animated login
    */

    // Prepare forms
    forms.each(function (i) {
        var form = $(this),
					height = form.outerHeight(),
					active = (hash === false && i === 0) || (hash === this.id),
					color = this.className.match(/[a-z]+-gradient/) ? ' ' + (/([a-z]+)-gradient/.exec(this.className)[1]) + '-active' : '';

        // Store size
        form.data('height', height);

        // Min-height for mobile layout
        if (maxHeight === false || height > maxHeight) {
            maxHeight = height;
        }

        // Button in the switch
        // KB: Let us not use title to display the captions for the buttons.        
        var formTitle = form.attr("formtitle");
        form.data('button', $('<a href="#' + this.id + '" class="button anthracite-gradient' + color + (active ? ' active' : '') + '">' + formTitle + '</a>')
									.appendTo(formSwitch)
									.data('form', form));

        // If active
        if (active) {
            // Store
            currentForm = form;

            // Height of viewport
            formViewport.height(height);
        }
        else {
            // Hide for now
            form.hide();
        }
    });

    // Main bloc height (without form height)
    blocHeight = formBlock.height(); // -currentForm.data('height');

    // Handle resizing (mostly for debugging)
    function handleLoginResize() {
        // Detect mode
        centered = (container.css('position') === 'absolute');

        // Set min-height for mobile layout
        if (!centered) {
            formWrapper.css('min-height', (blocHeight + maxHeight + 20) + 'px');
            container.css('margin-top', '');
        }
        else {
            formWrapper.css('min-height', '');
            if (parseInt(container.css('margin-top'), 10) === 0) {
                centerForm(currentForm, false);
            }
        }
    };

    // Register and first call
    $(window).bind('normalized-resize', handleLoginResize);
    handleLoginResize();

    // Switch behavior
    formSwitch.on('click', 'a', function (event) {

        var link = $(this),
					form = link.data('form'),
					previousForm = currentForm;

        event.preventDefault();
        if (link.hasClass('active')) {
            return;
        }

        // Refresh forms sizes
        forms.each(function (i) {
            var form = $(this),
						hidden = form.is(':hidden'),
						height = form.show().outerHeight();

            // Store size
            form.data('height', height);
            //KB: Hide Validation error callouts
            form.validationEngine('hide');
            // If not active
            if (hidden) {
                // Hide for now
                form.hide();
            }
        });


        // Clear messages
        formWrapper.clearMessages();

        // If an animation is already running
        if (animInt) {
            clearTimeout(animInt);
        }
        formViewport.stop(true);

        // Update active button
        currentForm.data('button').removeClass('active');
        link.addClass('active');

        // Set as current
        currentForm = form;

        // if CSS transitions are available
        if (doc.hasClass('csstransitions')) {
            // Close doors - step 1
            doors.removeClass('door-closed').addClass('door-down');
            animInt = setTimeout(function () {
                // Close doors, step 2
                doors.addClass('door-closed');
                animInt = setTimeout(function () {
                    // Hide previous form
                    previousForm.hide();

                    // Show target form
                    form.show();

                    // Center layout
                    centerForm(form, true);

                    // Height of viewport
                    formViewport.animate({
                        height: form.data('height') + 'px'
                    }, function () {
                        // Open doors, step 1
                        doors.removeClass('door-closed');
                        animInt = setTimeout(function () {
                            // Open doors - step 2
                            doors.removeClass('door-down');
                        }, 300);
                    });
                }, 300);
            }, 300);
        }
        else {
            // Close doors
            topDoor.animate({ top: '0%' }, 300);
            botDoor.animate({ top: '50%' }, 300, function () {
                // Hide previous form
                previousForm.hide();

                // Show target form
                form.show();

                // Center layout
                centerForm(form, true);

                // Height of viewport
                formViewport.animate({
                    height: form.data('height') + 'px'
                }, {

                    /* IE7 is a bit buggy, we must force redraw */
                    step: function (now, fx) {
                        topDoor.hide().show();
                        botDoor.hide().show();
                        formSwitch.hide().show();
                    },

                    complete: function () {
                        // Open doors
                        topDoor.animate({ top: '-50%' }, 300);
                        botDoor.animate({ top: '105%' }, 300);
                        formSwitch.hide().show();
                    }
                });
            });
        }
    });

    // Initial vertical adjust
    centerForm(currentForm, false);

    /*
    * Center function
    * param jQuery form the form element whose height will be used
    * param boolean animate whether or not to animate the position change
    * param string|element|array any jQuery selector, DOM element or set of DOM elements which should be ignored
    * return void
    */
    function centerForm(form, animate, ignore) {
        // If layout is centered
        if (centered) {
            var siblings = formWrapper.siblings().not('.closing'),
						finalSize = blocHeight + form.data('height');

            // Ignored elements
            if (ignore) {
                siblings = siblings.not(ignore);
            }

            // Get other elements height
            siblings.each(function (i) {
                finalSize += $(this).outerHeight(true);
            });

            // Setup
            container[animate ? 'animate' : 'css']({ marginTop: -Math.round(finalSize / 2) + 'px' });
        }
    };

    /**
    * Function to display error messages
    * param string message the error to display
    */
    function displayError(message, $customElement) {
        var wrapper = formWrapper;
        if ($customElement != null && $customElement.length > 0) {
            wrapper = $customElement;
        }
        // Show message
        var message = wrapper.message(message, {
            append: false,
            arrow: 'bottom',
            classes: ['red-gradient'],
            animate: false					// We'll do animation later, we need to know the message height first
        });

        // Vertical centering (where we need the message height)
        centerForm(currentForm, true, 'fast');

        // Watch for closing and show with effect
        message.bind('endfade', function (event) {
            // This will be called once the message has faded away and is removed
            centerForm(currentForm, true, message.get(0));

        }).hide().slideDown('fast');
    };

    /**
    * Function to display loading messages
    * param string message the message to display
    */
    function displayLoading(message, $customElement) {
        var wrapper = formWrapper;
        if ($customElement != null && $customElement.length > 0) {
            wrapper = $customElement;
        }
        // Show message
        var message = wrapper.message('<strong>' + message + '</strong>', {
            append: false,
            arrow: 'bottom',
            classes: ['blue-gradient', 'align-center'],
            stripes: true,
            darkStripes: false,
            closable: false,
            animate: false					// We'll do animation later, we need to know the message height first
        });

        // Vertical centering (where we need the message height)
        centerForm(currentForm, true, 'fast');

        // Watch for closing and show with effect
        message.bind('endfade', function (event) {
            // This will be called once the message has faded away and is removed
            centerForm(currentForm, true, message.get(0));

        }).hide().slideDown('fast');
    };


    function displaySuccess(message, $customElement) {
        var wrapper = formWrapper;
        if ($customElement != null && $customElement.length > 0) {
            wrapper = $customElement;
        }
        // Show message
        var message = wrapper.message(message, {
            append: false,
            arrow: 'bottom',
            classes: ['blue-gradient', 'align-center'],
            closable: false,
            animate: false					// We'll do animation later, we need to know the message height first
        });

        // Vertical centering (where we need the message height)
        centerForm(currentForm, true, 'fast');

        // Watch for closing and show with effect
        message.bind('endfade', function (event) {
            // This will be called once the message has faded away and is removed
            centerForm(currentForm, true, message.get(0));

        }).hide().slideDown('fast');
    };

    $("#btnGenerateToken").click(function (e) {

        var wrapper = $(".divRegistrationForm");
        // hide validation messages from previous form
        $("#form-verify").validationEngine("hide");
        e.preventDefault();
        wrapper.clearMessages();
        displayLoading("Please wait ...", wrapper);
        $.ajax('/Account/GenerateActivationEmail', {
            type: 'GET',
            success: function (response) {
                wrapper.clearMessages();
                formViewport.html(response);

            },
            error: function (err) {
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, wrapper);
                }
                else {
                    displayError(err, wrapper);
                }
            }
        });

        return false;
    });



    $("#btnGenerateActivationEmail,#btnReSendGenerateActivationEmail").live("click", function (e) {
        var wrapper = $(".divActivationForm");
        if ($("#form-generate-token").validationEngine('validate') == false) {
            return false;
        }
        wrapper.clearMessages();
        displayLoading("Generating confirmation email", wrapper);
        $.ajax('/Account/GenerateActivationEmail', {
            type: 'POST',
            data: { username: $("#username").val() },
            success: function (response) {
                wrapper.clearMessages();

                if (response.Status == "Success") {
                    displaySuccess("Activation link sent to your email", wrapper);
                    //                    notify('Activation Email', 'Activation link sent to your email', {
                    //                        autoClose: false,
                    //                        delay: 1500
                    //                    });
                }
                else {
                    displayError(response.ErrorMessage, wrapper);
                }
            },
            error: function (err) {
                formWrapper.clearMessages();
                if (err.status) {
                    displayError(err.status + ':' + err.statusText, wrapper);
                }
                else {
                    displayError(err, wrapper);
                }
            }
        });

        return false;
    });



});




