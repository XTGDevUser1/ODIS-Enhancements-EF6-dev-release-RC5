$(function () {

    // Global AJAX SET UP
    $(document).ajaxStart(function () {
        $.blockUI({ message: '<div class="ajax-load"/>',
            css: { background: 'transparent', border: '0px' }
        });
    })
    .ajaxStop(function () {
        $.unblockUI();
        $('html').css('cursor', 'pointer');

    })
   .ajaxError(function (err, errStatus) {
       HandleAjaxErrors(err, errStatus);
   });
});


function HandleAjaxErrors(err, errStatus) {
   
    var errorMessage = 'An error occurred while processing the request.';
    if (errStatus.status == 403) {
        Handle403(errStatus);
        return false;
    }
    try {
        var json = $.parseJSON(errStatus.responseText);
        if (json.Data == null) {
            errorMessage = json.ErrorMessage;
        }
        else {
            errorMessage = json.ErrorMessage + "<br/> Please contact administrator with the key [ " + json.Data + " ] for more details";
        }
    }
    catch (exception) {
        // possible error while parsing response as JSON
    }
    $.unblockUI();
    $('html').css('cursor', 'pointer');

    if (typeof (formWrapper) != "undefined") {
        formWrapper.clearMessages();
    }
    openAlertMessage(errorMessage);
}

function Handle403(errStatus) {

    openAlertMessage("Session timed out");
    var json = JSON.parse(errStatus.responseText);
    window.location = json.Data;

}

// Grid Related Methods
function GetWindowHeight() {
    if (window.innerHeight) {
        return window.innerHeight;
    }
    return document.documentElement.clientHeight;
}
function GetPopupWindowHeight() {
    var winHeight;
    if (window.innerHeight) {
        winHeight = window.innerHeight;
    }
    winHeight = document.documentElement.clientHeight;

    return winHeight - 100;
}



// Dirty Flag Handlers
var globalDirtyContainer = [];

$(function () {
    var confirmExit = function () {
        var len = globalDirtyContainer.length;
        if (len > 0) {
            return "You have attempted to leave this page.  If you have made any changes to the fields without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?";
        }
    }
    window.onbeforeunload = confirmExit;
});

function PromptForDirtyFlag() {
    return confirm("If you have made any changes to the fields without clicking the Save button, your changes will be lost.  Are you sure you want to exit this page?");
}

function WatchElementsForChange(containerName, excludedcontainerName, fnCallBack, routedValues) {
    if (excludedcontainerName == undefined) {
        $('#' + containerName + ' :input').live("change", function (e) {

            $('#' + containerName).attr("isDirty", "true");

            if (globalDirtyContainer.indexOf(containerName) == -1) {
                globalDirtyContainer.push(containerName);
            }
            if (fnCallBack != null) { fnCallBack($(this), routedValues); }
        });
    }
    else {

        $('#' + containerName + ' :input:not(#' + excludedcontainerName + ' :input)').live("change", function (e) {
            $('#' + containerName).attr("isDirty", "true");
            if (globalDirtyContainer.indexOf(containerName) == -1) {
                globalDirtyContainer.push(containerName);
            }
            if (fnCallBack != null) { fnCallBack($(this), routedValues); }
        });
    }
}

function WatchMyContainer(containerName, excludedcontainerName, fnCallBack, routedValues) {
    var containerInsertIndex = globalDirtyContainer.indexOf(containerName);
    if (containerInsertIndex == -1) {
        WatchElementsForChange(containerName, excludedcontainerName, fnCallBack, routedValues);
    }
    else {
        alert("Conatiner Name should be unique across");
    }
}
function CleanMyContainer(containerName) {
    $('#' + containerName).attr("isDirty", "false");

    var containerIndex = globalDirtyContainer.indexOf(containerName);
    if (containerIndex > -1) {
        globalDirtyContainer.splice(containerIndex, 1)
    }

    //Clear messages
    $(".formError").each(function () {
        $(this).remove();
    });
}

function IsMyContainerDirty(containerName) {
    if ($('#' + containerName).attr("isDirty") == "true") {
        return true;
    }
    return false;
}

function CleanAllContainers() {
    globalDirtyContainer = [];

    //Clear messages
    $(".formError").each(function () {
        $(this).remove();
    });
}

