function setFousRefreshGridIfExists(tabObjectReference, tabName, gridName) {
    if (tabObjectReference != undefined || tabObjectReference != null) {
        var tabID = $(tabObjectReference).attr('id');
        var tabContainerClassName = $(tabObjectReference).attr('data');

        //Verify that Tab does not exists.
        var nameToCheck = tabName;
        var tabNameExists = false;
        var index = -1;
        $('#' + tabID + ' ul li a').each(function (i) {
            if (this.text == nameToCheck) {
                tabNameExists = true;
                index = i;
            }
        });

        if (tabNameExists) {
            tabObjectReference.tabs('select', index);
            if (gridName != undefined && $('#' + gridName).data('kendoGrid') != undefined) {
                $('#' + gridName).data('kendoGrid').dataSource.read();
            }
        }
    }
}

function addGenericTab(tabTitle, tabContainerClassName, tabID, tabObjectReference, tabContent, tooltipText) {

    if (tabTitle == undefined || tabContainerClassName == undefined || tabID == undefined || tabObjectReference == undefined || tabContent == undefined) {
        openAlertMessage('Invalid use of Add Generic Tab, Reason could be supplied parameters are not valid');
        return false;
    }
    if (tooltipText == undefined || tooltipText == null) {
        tooltipText = tabTitle;
    }
    //Verify that Tab does not exists.
    var nameToCheck = tabTitle;
    var tabNameExists = false;
    var index = -1;
    $('#' + tabID + ' ul li a').each(function (i) {
        if (this.text == nameToCheck) {
            tabNameExists = true;
            index = i;
        }
    });

    if (tabNameExists) {
        tabObjectReference.tabs('select', index);
        return false;
    }

    var tabTemplate = '<li><a href="#{href}" class="with-tooltip tpComments" title="' + tooltipText + '">#{label}</a> <span class="ui-icon ui-icon-close">X</span></li>';
    var tabCounter = $(tabObjectReference).tabs("length") + 1;
    console.log("Trying to add Tab Current Count is " + tabCounter);
    var numOfTabs = tabCounter - 1;

    var lastTabId = $($("#" + tabID).find("." + tabContainerClassName)[numOfTabs - 1]);
    console.log("Trying to retrieve Last Tab ID " + lastTabId.attr("id"));

    var newTabId = parseInt(lastTabId.attr("id").replace("tabs-", "")) + 1;
    console.log("Next tab index : " + newTabId);

    var label = tabTitle || "Tab " + tabCounter,
        id = "tabs-" + newTabId,
        li = $(tabTemplate.replace(/#\{href\}/g, "#" + id).replace(/#\{label\}/g, label)),
        tabContentHtml = "Loading Details....";

    tabContentHtml = tabContent;
    tabObjectReference.find(".ui-tabs-nav").first().append(li);
    tabObjectReference.append("<div id='" + id + "' class='ui-tabs-panel " + tabContainerClassName + " ui-widget-content ui-corner-bottom ui-tabs-hide'>" + tabContentHtml + "</div>");
    tabObjectReference.tabs("refresh");
    tabObjectReference.tabs('option', 'active', false);
    tabObjectReference.tabs('select', tabCounter - 1);
    AdjustTooltipDimensions();
}

function deleteGenericTab(containerName, tabObjectReference, gridName, tabName) {

    if (containerName == undefined || tabObjectReference == undefined) {
        openAlertMessage('Invalid use of Delete Generic Tab, Reason could be supplied parameters are not valid');
        return false;
    }
    var parentTabIndex = tabObjectReference.tabs('', 'selected').find('.ui-tabs-selected')[0].firstElementChild.getAttribute('parenttabindex');
    var parentTabName = tabObjectReference.tabs('', 'selected').find('.ui-tabs-selected')[0].firstElementChild.getAttribute('parenttabname');
    // Sanghi In newer versions of jQueryUI (1.9 +) use active instead of selected to get the active index of tab.
    var activeIndex = tabObjectReference.tabs('option', 'selected');
    if (IsMyContainerDirty(containerName)) {
        var message = "Changes have not been saved; do you want to continue and lose the changes or cancel and go back to the page?";
        $.modal.confirm(message, function () {
            tabObjectReference.tabs('remove', activeIndex);
            tabObjectReference.tabs('refresh');
            //tabObjectReference.tabs('select', 0);
            CleanMyContainer(containerName);
            if (gridName != null && tabName != null) {
                setFousRefreshGridIfExists(tabObject, tabName, gridName);
            }
            if (parentTabIndex != null && parentTabName != null) {
                var indexToSelect = parseInt(parentTabIndex);
                var tabName = tabObjectReference.tabs('', 'selected')[0].getAttribute('id');
                var tabNameExists = false;
                $('#' + tabName + ' ul li a').each(function (i) {
                    if (this.text == parentTabName) {
                        tabNameExists = true;
                        index = i;
                    }
                });

                if (tabNameExists) {
                    tabObjectReference.tabs('select', indexToSelect);
                    return false;
                }
            }
            else {

                tabObjectReference.tabs('select', 0);

            }
        }, function () {
            return false;
        });
    }
    else {
        tabObjectReference.tabs('remove', activeIndex);
        tabObjectReference.tabs('refresh');

        if (gridName != null) {
            setFousRefreshGridIfExists(tabObject, tabName, gridName);
        }
        if (parentTabIndex != null && parentTabName != null) {
            var indexToSelect = parseInt(parentTabIndex);
            tabName = tabObjectReference.tabs('', 'selected')[0].getAttribute('id');
            var tabNameExists = false;
            $('#' + tabName + ' ul li a').each(function (i) {
                if (this.text == parentTabName) {
                    tabNameExists = true;
                    index = i;
                }
            });

            if (tabNameExists) {
                tabObjectReference.tabs('select', indexToSelect);
                return false;
            }
        }
        else {
            tabObjectReference.tabs('select', 0);
        }
    }
}

function canAddGenericTabInCurrentContainer(tabTitle, tabObjectReference) {
    var canAddNewTab = true;

    var tabID = $(tabObjectReference).attr('id');
    var tabContainerClassName = $(tabObjectReference).attr('data');

    //Verify that Tab does not exists.
    var nameToCheck = tabTitle;
    var tabNameExists = false;
    var index = -1;
    $('#' + tabID + ' ul li a').each(function (i) {
        if (this.text == nameToCheck) {
            tabNameExists = true;
            index = i;
        }
    });

    if (tabNameExists) {
        tabObjectReference.tabs('select', index);
        canAddNewTab = false;
    }

    return canAddNewTab;
}


function addGenericTabWithCurrentContainer(tabTitle, tabObjectReference, tabContent) {

    var tabID = $(tabObjectReference).attr('id');
    var tabContainerClassName = $(tabObjectReference).attr('data');
    if (tabTitle == undefined || tabContainerClassName == undefined || tabID == undefined || tabObjectReference == undefined || tabContent == undefined) {
        openAlertMessage('Invalid use of Add Generic Tab, Reason could be supplied parameters are not valid');
        return false;
    }
    
    //Verify that Tab does not exists.
    var nameToCheck = tabTitle;
    var tabNameExists = false;
    var index = -1;
    $('#' + tabID + ' ul li a').each(function (i) {
        if (this.text == nameToCheck) {
            tabNameExists = true;
            index = i;
        }
    });

    if (tabNameExists) {
        tabObjectReference.tabs('select', index);
        return false;
    }
    var parentTabIndex = tabObjectReference.tabs('option', 'selected');
    var parentTabName = tabObjectReference.tabs('', 'selected').find('.ui-tabs-selected')[0].firstElementChild.text;

    var tabTemplate = '<li><a href="#{href}" class="with-tooltip" parentTabIndex="' + parentTabIndex + '" parentTabName="' + parentTabName + '" title="' + tabTitle + '">#{label}</a> <span class="ui-icon ui-icon-close">X</span></li>';
    var tabCounter = $(tabObjectReference).tabs("length") + 1;
    console.log("Trying to add Tab Current Count is " + tabCounter);
    var numOfTabs = tabCounter - 1;

    var lastTabId = $($("#" + tabID).find("." + tabContainerClassName)[numOfTabs - 1]);
    console.log("Trying to retrieve Last Tab ID " + lastTabId.attr("id"));

    var newTabId = parseInt(lastTabId.attr("id").replace("tabs-", "")) + 1;
    console.log("Next tab index : " + newTabId);

    var label = tabTitle || "Tab " + tabCounter,
        id = "tabs-" + newTabId,
        li = $(tabTemplate.replace(/#\{href\}/g, "#" + id).replace(/#\{label\}/g, label)),
        tabContentHtml = "Loading Details....";

    tabContentHtml = tabContent;
    tabObjectReference.find(".ui-tabs-nav").first().append(li);
    tabObjectReference.append("<div id='" + id + "' class='ui-tabs-panel " + tabContainerClassName + " ui-widget-content ui-corner-bottom ui-tabs-hide'>" + tabContentHtml + "</div>");
    tabObjectReference.tabs("refresh");
    tabObjectReference.tabs('option', 'active', false);
    tabObjectReference.tabs('select', tabCounter - 1);
}

