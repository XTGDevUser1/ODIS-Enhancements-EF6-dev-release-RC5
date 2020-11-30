$(function () {
    var doc = $('html').addClass('js-login'),
				container = $('#container'),
				formWrapper = $('#form-wrapper'),
				formBlock = $('#form-block'),
				formViewport = $('#form-viewport'),
				forms = formViewport.children('form'),
                currentForm = $("#form-verify");
    $('#form-verify').submit(function (event) {
        
        if ($("#form-verify").validationEngine('validate') == false) {
            return false;
        }
        // Values
        var vendorNumber = $.trim($('#VendorNumber').val()),
		taxID = $.trim($('#TaxID').val());

        // Remove previous messages
        formWrapper.clearMessages();

        // Show progress
        displayLoading('Verifying ...');

        // Stop normal behavior
        event.preventDefault();
        var vendorIdentity = {
            VendorNumber: vendorNumber,
            TaxID: taxID
        };

        // This is where you may do your AJAX call, for instance:
        $.ajax('/Register/Index', {
            type: 'POST',
            data: vendorIdentity,
            success: function (json) {
                // Remove previous messages
                formWrapper.clearMessages();
                if (json.Status == "NotFound") {
                    displayError("Information not found, please try again or call Vendor Services at 800-555-5555");
                }
                else if (json.Status == "Registered") {
                    displayError("Already registered.  Go to login screen and login or use the forgot username/password feature");
                }
                else if (json.Status == "NotRegistered") {
                    // Redirect the url to Register page.
                }
                else if (json.errors) {
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
