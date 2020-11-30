/**
* Display a confirm prompt
* @param string message the message, as text or html
* @param function confirmCallback the function called when hitting confirm
* @param function cancelCallback the function called when hitting cancel or closing the modal
* @param object options same as $.modal() (optional)
* @return jQuery the new window
*/
$.modal.confirmFeedback = function (message, confirmCallback, cancelCallback, options) {
    options = options || {};

    // Cancel callback
    var isConfirmed = false,
			onClose = options.onClose;
    options.onClose = function (event) {
        // Cancel callback
        if (!isConfirmed) {
            cancelCallback.call(this);
        }

        // Previous onClose, if any
        if (onClose) {
            onClose.call(this, event);
        }
    };

    // Open modal
    $.modal($.extend({}, $.modal.defaults.confirmOptions, options, {

        content: message,
        buttons: {

            'Done': {
                classes: 'glossy',
                click: function (modal) { modal.closeModal(); }
            },

            'Send another': {
                classes: 'blue-gradient glossy',
                click: function (modal) {
                    // Mark as sumbmitted to prevent the cancel callback to fire
                    isConfirmed = true;

                    // Callback
                    confirmCallback.call(modal[0]);

                    // Close modal
                    modal.closeModal();
                }
            }

        }

    }));
};