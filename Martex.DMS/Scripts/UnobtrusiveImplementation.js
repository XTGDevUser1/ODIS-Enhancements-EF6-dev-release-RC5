if (!Function.prototype.bind) {
    Function.prototype.bind = function (oThis) {
        if (typeof this !== "function") {
            // closest thing possible to the ECMAScript 5 internal IsCallable function
            throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
        }

        var aArgs = Array.prototype.slice.call(arguments, 1),
        fToBind = this,
        fNOP = function () { },
        fBound = function () {
            return fToBind.apply(this instanceof fNOP
                                 ? this
                                 : oThis || window,
                               aArgs.concat(Array.prototype.slice.call(arguments)));
        };

        fNOP.prototype = this.prototype;
        fBound.prototype = new fNOP();

        return fBound;
    };
}

$(function () {

    $("#btnSearchMap").live('click', function () {

        //Validation Message
        if ($.trim($('#SearchLocation').val()) == '') {
            $('#SearchLocation').validationEngine('showPrompt', 'Search location is required.', '', 'topRight', true);
        }

        if ($("#frmCall").validationEngine('validate') == false) {
            return false;
        }

        $("#frmCall").validationEngine('hide');
        //Validation ends here
        genericMapping.searchLocation($('#SearchLocation').val(), function (locations) {
            $.each(locations, function (index, value) {
                //value.customIconUrl = "/Content/images/poi_search_red.png";

                $("#SourceSearchSelect")
                .append($("<option>", { value: JSON.stringify(value) })
                .text(value.description));
            });
            if (locations.length > 0) {

                genericMapping.clearMap();
                genericMapping.addPins([locations[0]], true, false, {});
                
                var lat = [locations[0]][0].latitude;
                var long = [locations[0]][0].longitude;

                genericMapping.provider.map.setView({ zoom: 15, center: new Microsoft.Maps.Location(lat, long) });
                //Global Variable
                isPinned = true;
                ShowMapHeader("0", "");
                if ($.inArray([locations[0]][0].description, availableTags) == -1) {
                    availableTags.push([locations[0]][0].description);
                }
                SetValues();
                //to do assign the values and checked the location length above
                //Assign Latitude and Longitude to Page.

                $("#EmergencyAssistance_Latitude").val(locations[0].latitude);
                $("#EmergencyAssistance_Longitude").val(locations[0].longitude);
                $("#EmergencyAssistance_Address").val([locations[0]][0].description);
            }

        });

        return false;
    });
    $("#btnPin").click(function () {
        genericMapping.addPins([JSON.parse($("#SourceSearchSelect").val())], true, false);
    });
    $("#SourceReverseGeocodeButton").click(function () {
        genericMapping.reverseGeocodeLocation($("#SourceLatitudeTextBox").val(), $("#SourceLongitudeTextBox").val(), function (location) {
            genericMapping.addPins([location], true, false);
        });
    });
    $("#SourceFindBusinessButton").click(function () {
        var searchCenterLocation;
        genericMapping.searchLocation("130 E. John Carpenter Fwy., Irving, TX", function (location) {
            genericMapping.addPins([location[0]], true, false);

            genericMapping.searchBusiness(location[0], $("#SourceFindBusinessTextBox").val(), function (locations) {
                $.each(locations, function (index, value) {
                    value.setToDestClickCallback = function (location) {
                        var bob = location; /*TODO: Set global dest to this location object*/
                    };
                });
                genericMapping.addPins(locations, true, true);
                genericMapping.removePins([locations[3], locations[4]]);
            });
        });
    });
    $("#ClickToPinButton").click(function () {
        genericMapping.toggleClickToPin();
    });
    $("#ClickToZoomButton").click(function () {
        genericMapping.toggleClickToZoom();
    });
    $("#PinExitsButton").click(function () {
        var zoomLevel = genericMapping.getZoomLevel();

        if (zoomLevel < 14) {
            alert("Can't pin exits at this zoom...please zoom in to a smaller area.");
        }
        else {
            genericMapping.searchHighwayExits(function (locations) {
                genericMapping.addPins(locations, true, false);
            });
        }
    });
    $("#CalculateRouteButton").click(function () {
        var locations = [];
        genericMapping.searchLocation("130 E. John Carpenter Fwy., Irving, TX", function (locationResultx) {
            genericMapping.addPins([locationResultx[0]], true, false);
            locations.push(locationResultx[0]);

            genericMapping.searchLocation("5207 Victor St., Dallas, TX", function (locationResult) {
                genericMapping.addPins([locationResult[0]], true, false);
                locations.push(locationResult[0]);

                var totalDistance;
                genericMapping.calculateRoute(locations, function (totalDistance) {
                    if (totalDistance != null) {
                        alert(totalDistance.toString());
                    }
                });

                genericMapping.calculateDistance(locations, function (totalDistance) {
                    if (totalDistance != null) {
                        alert(totalDistance.toString());
                    }
                });
            });
        });
    });

    $("#RemovePinsButton").click(function () {
        genericMapping.clearMap();
    });
});