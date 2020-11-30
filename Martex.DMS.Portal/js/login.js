


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
				container = $('#container'),
				formWrapper = $('#form-wrapper'),
				formBlock = $('#form-block'),
				formViewport = $('#form-viewport'),
				forms = formViewport.children('form'),

    // Doors
				topDoor = $('<div id="top-door" class="form-door"><div></div></div>').appendTo(formViewport),
				botDoor = $('<div id="bot-door" class="form-door"><div></div></div>').appendTo(formViewport),
				doors = topDoor.add(botDoor),

    // Switch
				formSwitch = $('<div id="form-switch"><span class="button-group"></span></div>').appendTo(formBlock).children(),

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

        var rememberme = $('#login_rememberme').val();
        var returnUrl = $('#returnUrl').val();
        var deviceName = "";

        if (document.applets && document.applets.length > 0) {
            if (typeof document.applets[0].getDeviceName != "undefined") {
                deviceName = document.applets[0].getDeviceName();
            }
        }

        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Checking credentials...');

        // Stop normal behavior
        event.preventDefault();
        var loginmodel = {
            UserName: username,
            Password: password,
            RememberMe: (rememberme) ? true : false,
            ReturnUrl: returnUrl,
            DeviceName: deviceName
        };

        // This is where you may do your AJAX call, for instance:
        $.ajax('JsonLogOn', {
            type: 'POST',
            data: loginmodel,
            success: function (json) {

                if (json.success) {
                    // Redirect the user to home page

                    location = json.redirect || "/";
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
        // Simulate server-side check
        setTimeout(function () {
            document.location.href = './'
        }, 2000);

    });

    /*
    * Password recovery
    */
    $('#form-password').submit(function (event) {

        if ($("#form-password").validationEngine('validate') == false) {
            return false;
        }

        // Values
        var userName = $.trim($('#forgotpassword_username').val());

        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Sending credentials...');

        // Stop normal behavior
        event.preventDefault();

        /*
        * This is where you may do your AJAX call
        */

        $.ajax('/Account/JsonForgotPassword', {
            type: 'POST',
            data: { username: userName },
            success: function (json) {

                if (json.success) {
                    formWrapper.clearMessages();
                    notify('Forgot password', 'Password sent to your email', {
                        autoClose: false,
                        delay: 1500,
                        icon: '/img/demo/icon.png'
                    });
                } else if (json.errors) {
                    var items = $.map(json.errors, function (error) {
                        return error;
                    }).join('');
                    formWrapper.clearMessages();
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
                    notify('Registration', 'User created successfully', {
                        autoClose: false,
                        delay: 1500,
                        icon: 'img/demo/icon.png'
                    });
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
    blocHeight = formBlock.height() - currentForm.data('height');

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
    function displayError(message) {
        // Show message
        var message = formWrapper.message(message, {
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
    function displayLoading(message) {
        // Show message
        var message = formWrapper.message('<strong>' + message + '</strong>', {
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
});

     // What about a notification?
     //        notify('Alternate login', 'Want to see another login page style? Try the <a href="login.html"><b>default version</b></a> or the <a href="login-box.html"><b>box version</b></a>.', {
     //            autoClose: false,
     //            delay: 2500,
     //            icon: 'img/demo/icon.png'
     //        });
