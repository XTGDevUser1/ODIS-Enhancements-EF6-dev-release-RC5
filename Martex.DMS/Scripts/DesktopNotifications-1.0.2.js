var isDesktopNotificationEnabled = true;
var hub = null;
$(function () {
    
    if (isDesktopNotificationEnabled) {
        if (notify.hasNotificationAPI()) {
            if (!notify.isNotificationPermissionSet()) {
                notify.showNotificationPermission('Your browser supports desktop notification, click here to enable them.', function() {
                    // Confirmation message
                    if (notify.hasNotificationPermission()) {
                        notify('Notifications API enabled!', 'You can now see notifications even when the application is in background', {
                            icon: 'img/demo/icon.png',
                            system: true
                        });
                    } else {
                        notify('Notifications API disabled!', 'Desktop notifications will not be used.', {
                            icon: 'img/demo/icon.png'
                        });
                    }
                });
            } 
        }
        else {
            //$.modal.alert('Your browser does not support the notification API');
        }
    }
});

$(function () {

    $.connection.hub.start().done(function () {

    });

    // Retrieve Hub Reference
    hub = $.connection.notificationHub;

    //Broad Cast Call Back Function
    hub.client.processBroadcastCallBack = function (message) {
        ShowNotifications(message);
    };
    hub.client.processBroadcastCallBackSuccess = function (message) {
        ShowNotifications(message);
    };

    //Send Message Call Back funtion
    hub.client.sendMessageCallBack = function (message, autoCloseDelay) {
        ShowNotifications(message, autoCloseDelay);
    };

    hub.client.sendMessageCallBackSuccess = function (message) {
        ShowNotifications(message);
    };

    //Error Call Back when User is not online or invalid user
    hub.client.showErrorMessageCallBack = function (message) {
        ShowNotifications(message);
    };
});

// Helper to Show Notifications
function ShowNotifications(message, autoCloseDelay) {

    console.log("Show Notifications Message : " + message);

    var autoClose = true;
    if (autoCloseDelay <= 0) {
        autoClose = false;
    }
    
    
    // Gather options
    notify('ODIS Alert!', message, {
        system: true,
        vPos: 'top',
        hPos: 'right',
        autoClose: autoClose,
        closeDelay: autoCloseDelay == null || autoCloseDelay < 0 ? 8000 : autoCloseDelay * 1000,
        icon: '/Content/img/odis-user.png',
        iconOutside: true,
        closeButton: true,
        showCloseOnHover: true,
        groupSimilar: false
    });
}

//Server Broad Cast
function ServerBroadCastMessage(message) {
    hub.server.broadcast(message);
}

function ServerSendMessage(whom, message) {
    hub.server.sendMessage(whom, message).done(function (response) {
        
    });
}