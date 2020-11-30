var BingMaps = function () { };
var removePinsCalled = false;

BingMaps.Location = function (latitude, longitude, description, boundingBox) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.description = description;
    this.boundingBox = boundingBox;
    this.id = BingMaps.uniqueId();
    this.StateProvince = '';
    this.Country = '';
};

BingMaps.uniqueId = (function () {
    var id = 0;
    return function () { return id++; };
})();

BingMaps.prototype = function () {

    //#region Private variables
    //DEV KEYS
    //var bingMapsKey = "AnicFtk4cQ9nwJo3qfmpFBupyUlxAYA6H8phcUbfPR_ort_WGtnQr8MIbFCMD-zq";
    //var bingKey = "F68E23262777D58412FF9EF14AF6AEF6230B1845";

    //PROD KEYS
    var bingMapsKey = "Ag37nsHBx8BxsIiXtl5qxfYNY7tt6s-aKky73p8iYA3vdZ8NDx3YCC7L1WWAgCEK"; // "AiCxnleqgXn7NC_nPmLMfek8lCJZdKtJ279g4aQMeUBuTD_CjqxnGfJ0ZyZfvNiy";
    var bingKey = "28FAB69405E084C0565AC62502F692083CC53F13";

    //Qurey URLs
    var bingLocationApiUrl = "http://dev.virtualearth.net/REST/v1/Locations/";
    var bingSpatialApiUrl = "http://spatial.virtualearth.net/REST/v1/data/";
    var bingRoutesApiUrl = "http://dev.virtualearth.net/REST/v1/Routes/";
    var bingPhonebookApiUrl = "http://api.bing.net/json.aspx";

    var clickToPinHandler;
    var clickToZoomHandler;
    var pinMouseMoveHandler;
    var mapDiv;
    var directionsDiv;
    var mapOptions;
    var map;
    var directionsManager;
    var scrollBarVertOffset;
    var infoboxSeed;
    var searchManager = null;
    //#endregion

    //#region Private Handlers
    var pinMouseOverHandler = function (e) {
        var pin = e.target;
        var infobox = e.target.infobox;

        makeInfoboxVisible.bind(this, pin)();

    }

    var pinMouseOutHandler = function (e) {
        var pin = e.target;

        makeInfoboxInvisible.bind(this, pin)();
    }

    var mouseDoubleClickHandler = function (e) {
        e.handled = true;
        return;
    }

    var mouseWheelHandler = function (e) {
        e.handled = true;
    }

    var addPinClickHandler = function (e) {
        if (e.targetType == "map") {
            var ecx = e.originalEvent.clientX;
            var ecy = e.originalEvent.clientY;

            //3/22/12 calculates the difference in the vertical offset from the time the map was generated to the current offset
            var currentScrollBarOffset = document.body.scrollTop;
            var diff = scrollBarVertOffset - currentScrollBarOffset;

            var point = new Microsoft.Maps.Point(ecx, (ecy - diff));
            var location = e.target.tryPixelToLocation(point, Microsoft.Maps.PixelReference.page);
            //var point = new Microsoft.Maps.Point(e.getX(), e.getY());
            //var location = e.target.tryPixelToLocation(point);
            //04/20/12 - Code to retrieve session credentials. Used on subsequent calls to REST services so that
            //            those hits on Microsoft's system will be non-billable. MJ KS2
            var context = this;
            this.map.getCredentials(function (credentials) {
                bingMapsKey = credentials;

                $.ajax({
                    type: "GET",
                    dataType: "jsonp",
                    url: bingLocationApiUrl + location.latitude.toString() + "," + location.longitude.toString(),
                    jsonp: "jsonp",
                    data: {
                        key: bingMapsKey,
                        includeEntityTypes: "Address"
                    },
                    context: context,
                    success: function (json) {
                        var address = addPinClickCallback.bind(this, json, location)();
                        var internalLocation = new BingMaps.Location(location.latitude, location.longitude, address, null);
                        addPins.bind(this, [internalLocation], true, false)();
                        document.form1.address2.value = address;
                    }
                });
            });
        }
    }

    var addZoomClickHandler = function (e) {
        if (e.targetType == "map") {
            var zoomLevel = this.map.getZoom();

            var ecx = e.originalEvent.clientX;
            var ecy = e.originalEvent.clientY;
            //3/22/12 calculates the difference in the vertical offset from the time the map was generated to the current offset
            var currentScrollBarOffset = document.body.scrollTop;
            var diff = scrollBarVertOffset - currentScrollBarOffset;

            var point = new Microsoft.Maps.Point(ecx, (ecy - diff));
            var location = e.target.tryPixelToLocation(point, Microsoft.Maps.PixelReference.page);

            //var point = new Microsoft.Maps.Point(e.getX(), e.getY());
            //var location = e.target.tryPixelToLocation(point);
            //TODO: if we want to restrict the zoom level, we would check to see if it is greater than
            //the value we want to be the "highest" resolution here instead of incrementing every time
            this.map.setView({ zoom: ++zoomLevel, center: location });
        }
    }

    var pinMouseMoveHandler = function (e) {
        var mapElem = this.map.getRootElement();
        if (e.targetType === "map") {
            mapElem.style.cursor = "crosshair";
        }
        else {
            mapElem.style.cursor = "pointer";
        }
    }

    var infoboxClickHandler = function (e) {

        if (e.targetType == "infobox") {
            var infobox = e.target;
            var offset = $("#" + infobox.setToDestButtonId).offset();
            var x = offset.left;
            var y = offset.top;
            var xdelta = $("#" + infobox.setToDestButtonId).outerWidth();
            var ydelta = $("#" + infobox.setToDestButtonId).outerHeight();
            var x2 = x + xdelta;
            var y2 = y + ydelta;

            var clickX = e.pageX;
            var clickY = e.pageY;

            if (clickX > x && clickX < x2 && clickY > y && clickY < y2) {
                $("#" + infobox.setToDestButtonId).attr("src", "/images/set-dest-btn-hover.gif");
                if (infobox.setToDestClickCallback != null) {
                    infobox.setToDestClickCallback(infobox.pin._location);
                    makeInfoboxInvisible(infobox.pin);
                }
                setTimeout(function () { $("#" + infobox.setToDestButtonId).attr("src", "/images/set-dest-btn.gif"); }, 100);
            }

        }
    }

    var infoboxCloseClickHandler = function (e) {
        var infoboxSetToDestId = e.currentTarget.id.replace(/Anchor$/i, "");

        var foundItem = null;
        for (var i = 0; i < this.map.entities.getLength(); i++) {
            var e = this.map.entities.get(i);
            if (e instanceof Microsoft.Maps.Infobox && e.setToDestButtonId != null && e.setToDestButtonId == infoboxSetToDestId) {
                foundItem = e;
                break;
            }
        }

        if (foundItem != null) {
            makeInfoboxInvisible(foundItem.pin);
        }
    }

    var viewChangeStartHandler = function (e) {
        for (var i = 0; i < this.map.entities.getLength(); i++) {
            var e = this.map.entities.get(i);
            if (e instanceof Microsoft.Maps.Infobox && e.pin != null) {
                makeInfoboxInvisible(e.pin);
            }
        }
    }

    var viewChangeEndHandler = function (e) {
        var elementList = document.getElementsByTagName("div");

        /*for (i = 0; i < elementList.length; i++){
        var thisElement = elementList[i];
        if(thisElement.className == "NavBar_compassControlContainer") {
        thisElement.style.visibility = "hidden";
        }
        if(thisElement.className == "NavBar_zoomDrop") {
        thisElement.style.visibility = "hidden";
        }
        }*/
    }

    var _eventHandlerMagic = function () {

        var callbackFunc;

        return {
            init: function (callback) {
                callbackFunc = callback;
            },
            directionsUpdatedHandler: function (e) {
                if (e != null && e.routeSummary != null && e.routeSummary.length > 0) {
                    callbackFunc(e.routeSummary[0].distance, e.routeSummary[0].time, e.routeSummary[0].timeWithTraffic);
                }
            }
        };
    } ();
    //#endregion

    //#region Private Callbacks
    var findLocationCallback = function (json) {
        if (json != null &&
		        json.resourceSets != null &&
		        json.resourceSets.length > 0 &&
		        json.resourceSets[0].resources != null &&
		        json.resourceSets[0].resources.length > 0) {

            if (json.resourceSets[0].resources.length >= 1) {
                var locations = [];

                for (var i = 0; i < json.resourceSets[0].estimatedTotal; i++) {
                    var value = json.resourceSets[0].resources[i];

                    if (value != null &&
		                    value.point != null &&
		                    value.point.coordinates != null &&
		                    value.point.coordinates.length > 1) {
                        var latitude = value.point.coordinates[0];
                        var longitude = value.point.coordinates[1];

                        var bbox = {};
                        if (value.bbox != null && value.bbox.length > 3) {
                            bbox.south = value.bbox[0];
                            bbox.west = value.bbox[1];
                            bbox.north = value.bbox[2];
                            bbox.east = value.bbox[3];
                        }

                        var location = new BingMaps.Location(latitude, longitude, value.name, bbox);
                        // KB: Added city, state, postalCode and country
                        location.StateProvince = value.address.adminDistrict;
                        location.Country = value.address.countryRegion;
                        location.City = value.address.locality;
                        location.PostalCode = value.address.postalCode;
                        locations.push(location);
                    }
                }

                return locations;
            }
        }
    }

    var addPinClickCallback = function (json, location) {
        var address = "";

        if (json != null &&
        json.resourceSets != null &&
        json.resourceSets.length > 0 &&
        json.resourceSets[0].resources != null &&
        json.resourceSets[0].resources.length > 0) {
            address = json.resourceSets[0].resources[0].name;
        }

        return address;
    }

    var createDirectionsManagerCallback = function (locations) {
        this.directionsManager = new Microsoft.Maps.Directions.DirectionsManager(this.map);

        this.directionsManager.setRenderOptions(
        { itineraryContainer: this.directionsDiv,
            displayRouteSelector: false,
            displayManeuverIcons: false,
            displayPostItineraryItemHints: false,
            displayPreItineraryItemHints: false,
            displayStepWarnings: false,
            displayTrafficAvoidanceOption: false,
            waypointPushpinOptions: { draggable: false }
        });
        this.directionsManager.setRequestOptions({ routeDraggable: false });

        return getDirections.bind(this, locations)();
    }

    var getHighwayExitsCallback = function (json) {
        if (json != null &&
	        json.d != null &&
	        json.d.results != null &&
	        json.d.results.length > 0) {
            var locations = [];
            for (i = 0; i < json.d.results.length; i++) {
                locations.push(new BingMaps.Location(json.d.results[i].Latitude, json.d.results[i].Longitude, json.d.results[i].DisplayName, null));
            }
            return locations;
        }
    }

    var calculateDistanceCallback = function (json) {
        if (json != null &&
        json.resourceSets != null &&
        json.resourceSets.length > 0 &&
        json.resourceSets[0].resources != null &&
        json.resourceSets[0].resources.length > 0
        ) {
            return json.resourceSets[0].resources[0].travelDistance;
        }
    }
    //#endregion

    //#region Private Helpers
    var getMap = function (ent) {
        window.location.hash = "map";
        ent.map = new Microsoft.Maps.Map(ent.mapDiv, ent.mapOptions);
        //alert("Page:(" + this.map.getPageX().toString() + "," + this.map.getPageY().toString() + ") " + "Viewport:(" + this.map.getViewportX().toString() + "," + this.map.getViewportY().toString() + ") " + "W/H:(" + this.map.getWidth().toString() + "," + this.map.getHeight().toString() + ")");
        Microsoft.Maps.Events.addHandler(ent.map, "mousewheel", mouseWheelHandler);
        Microsoft.Maps.Events.addHandler(ent.map, "viewchangestart", viewChangeStartHandler.bind(ent));
        Microsoft.Maps.Events.addHandler(ent.map, "viewchangeend", viewChangeEndHandler.bind(ent));
        Microsoft.Maps.Events.addHandler(ent.map, 'dblclick', mouseDoubleClickHandler);

        //3/22/12 - Code to capture vertical offset.  Used to fix click to pin and click to zoom issue.  MJ KS2
        if (scrollBarVertOffset == null) {
            scrollBarVertOffset = document.body.scrollTop;
            //alert(scrollBarVertOffset);
        }
    }

    var makeInfoboxVisible = function (pin) {
        var infobox = pin.infobox;
        infobox.setOptions({ visible: true });

        var pinPos = this.map.tryLocationToPixel(pin.getLocation());
        pinPos.y -= 34;

        var newPinLocation = this.map.tryPixelToLocation(pinPos);
        infobox.setLocation(newPinLocation);

        $("#" + infobox.setToDestButtonId + "Anchor").click(infoboxCloseClickHandler.bind(this));
    }

    var makeInfoboxInvisible = function (pin) {
        var infobox = pin.infobox;
        infobox.setOptions({ visible: false });
    }

    var setLocation = function (pin, searchType) {
        switch (searchType) {
            case this.searchTypes.Source: this.sourceLocation = pin; break;
            case this.searchTypes.Destination: this.destLocation = pin; break;
        }
    }

    var getDirections = function (locations) {
        if (locations.length > 1) {
            for (var i = 0; i < locations.length; i++) {
                this.directionsManager.addWaypoint(new Microsoft.Maps.Directions.Waypoint({ location: new Microsoft.Maps.Location(locations[i].latitude, locations[i].longitude) }));
            }

            Microsoft.Maps.Events.addHandler(this.directionsManager, "directionsUpdated", _eventHandlerMagic.directionsUpdatedHandler);
            this.directionsManager.calculateDirections();
        }
    }

    var recalculateMapViewport = function (location) {

        var locations = [];
        var lastPin;
        var firstPin;
        var pinFound = false;

        for (var i = 0; i < this.map.entities.getLength(); i++) {
            var e = this.map.entities.get(i);
            if (e instanceof Microsoft.Maps.Pushpin) {
                lastPin = e;
                locations.push(e.getLocation());
            }
        }

        /*var northWestLoc = new Microsoft.Maps.Location(lastPin.boundingBox.north, lastPin.boundingBox.west);
        var southEastLoc = new Microsoft.Maps.Location(lastPin.boundingBox.south, lastPin.boundingBox.east);

        this.map.setView({ bounds: Microsoft.Maps.LocationRect.fromCorners(northWestLoc, southEastLoc), center: e.getLocation() });*/

        if (locations.length == 1) {
            if (lastPin.boundingBox != null) {
                var northWestLoc = new Microsoft.Maps.Location(lastPin.boundingBox.north, lastPin.boundingBox.west);
                var southEastLoc = new Microsoft.Maps.Location(lastPin.boundingBox.south, lastPin.boundingBox.east);

                this.map.setView({ bounds: Microsoft.Maps.LocationRect.fromCorners(northWestLoc, southEastLoc), center: e.getLocation() });
            }
        } else {
            var viewport = Microsoft.Maps.LocationRect.fromLocations(locations);
            this.map.setView({ bounds: viewport });
        }
    }
    //#endregion

    //#region Public Methods
    var init = function (mapDiv, directionsDiv) {
        this.mapDiv = mapDiv;
        this.directionsDiv = directionsDiv;
        this.mapOptions = {
            credentials: bingMapsKey,
            mapTypeId: Microsoft.Maps.MapTypeId.road,
            disableBirdseye: true,
            showMapTypeSelector: true,
            enableClickableLogo: false,
            enableSearchLogo: false,
            showCopyright: false,
            showDashboard: true,
            showLogo: false,
            theme: (typeof Microsoft.Maps.Themes.BingTheme != "undefined") ? new Microsoft.Maps.Themes.BingTheme() : null
        };
        this.infoboxSeed = 0;
    }

    var searchLocation = function (searchText, callback) {
        if (this.map == null) {
            getMap(this);
        }
        var context = this;

        //04/20/12 - Code to retrieve session credentials. Used on subsequent calls to REST services so that
        //            those hits on Microsoft's system will be non-billable. MJ KS2
        this.map.getCredentials(function (credentials) {
            bingMapsKey = credentials;

            $.ajax({
                type: "GET",
                dataType: "jsonp",
                url: bingLocationApiUrl,
                jsonp: "jsonp",
                data: {
                    key: bingMapsKey,
                    q: searchText
                },
                context: context,
                success: function (json) {
                    var locations = findLocationCallback.bind(this, json)();
                    callback(locations);
                }
            });
        });
    }

    var reverseGeocodeLocation = function (latitude, longitude, callback) {
        if (this.map == null) {
            getMap(this);
        }

        var context = this;

        //04/20/12 - Code to retrieve session credentials. Used on subsequent calls to REST services so that
        //            those hits on Microsoft's system will be non-billable. MJ KS2
        this.map.getCredentials(function (credentials) {
            bingMapsKey = credentials;

            $.ajax({
                type: "GET",
                dataType: "jsonp",
                url: bingLocationApiUrl + latitude.toString() + "," + longitude.toString(),
                jsonp: "jsonp",
                data: {
                    key: bingMapsKey
                },
                context: context,
                success: function (json) {
                    var location = findLocationCallback.bind(this, json)();
                    callback(location);
                }
            });
        });
    }

    var addPins = function (locations, hasInfobox, hasSetDestination, infoBoxOptions) {

        var mapLocations = $.map(locations, function (e) { return new Microsoft.Maps.Location(e.latitude, e.longitude); });
        for (var i = 0; i < mapLocations.length; i++) {
            var pin = new Microsoft.Maps.Pushpin(mapLocations[i]);
            pin.boundingBox = locations[i].boundingBox;

            if (locations[i].customIconUrl != null) {
                var pinText = "" + (i + 1); //KB: By default set numbered pins if a custom icon is provided.
                if (typeof locations[i].pinText != "undefined") {
                    pinText = locations[i].pinText;
                }
                pin.setOptions({ icon: locations[i].customIconUrl, text: pinText, height: 50, width: 25 });
            }

            if (hasInfobox) {
                var infobox = null;
                if (infoBoxOptions != null) {
                    infobox = new Microsoft.Maps.Infobox(mapLocations[i], infoBoxOptions);
                }
                else {
                    infobox = new Microsoft.Maps.Infobox(mapLocations[i], { visible: false });
                }
                if (hasSetDestination) {


                    var setToDestButtonId = "InfoboxSetToDest" + this.infoboxSeed.toString();
                    infobox.contentDivId = "infobox" + (this.infoboxSeed++).toString();
                    infobox.setHtmlContent("<div id=\""
                    		+ infobox.contentDivId + "\" class=\"Infobox custom-infobox\"><a id=\""
                    		+ setToDestButtonId + "Anchor\" class=\"infobox-close\">x</a><div class=\"infobox-body\"><div class=\"infobox-title\">"
                    		+ locations[i].description + "</div></div><div class=\"infobox-button\"><img id=\""
                    		+ setToDestButtonId + "\" src=\"/images/set-dest-btn-hover.gif\" alt=\"Set to destination\" /></div><div class=\"custom-infobox-stalk infobox-stalk\"></div></div>");
                    infobox.setToDestButtonId = setToDestButtonId;
                    locations[i].setToDestButtonId = setToDestButtonId;
                    infobox.setToDestClickCallback = locations[i].setToDestClickCallback;

                    Microsoft.Maps.Events.addHandler(pin, "click", pinMouseOverHandler.bind(this));
                    Microsoft.Maps.Events.addHandler(infobox, "click", infoboxClickHandler.bind(this));

                }
                else {


                    //Added below line to test fix for issue 51.  4/16/12 MJ

                    infobox.setOptions({ title: locations[i].description });
                    Microsoft.Maps.Events.addHandler(pin, "click", pinMouseOverHandler.bind(this));
                    // Added the event on MAP and handle the type at UI level.
                    //  Microsoft.Maps.Events.addHandler(this.map, 'click', onCustomPushPinClick.bind(this, hasInfobox));

                    //Commented the below lines out to test fix for issue 51.  4/16/12 MJ
                    //Microsoft.Maps.Events.addHandler(pin, "mouseover", pinMouseOverHandler.bind(this));
                    //Microsoft.Maps.Events.addHandler(pin, "mouseout", pinMouseOutHandler.bind(this));
                }

                pin.infobox = infobox;
                infobox.pin = pin;

                this.map.entities.push(infobox);
            }
            // KS: Extended the method to call a custom callback to help launch a custom popup.
            // Developers should implement a function that reads onMapClick(location, sender) and implement the custom logic in that function.
            else {
                if (typeof onMapClick != "undefined") {
                    Microsoft.Maps.Events.addHandler(pin, "click", onMapClick.bind(this, locations[i]));
                }
            }

            this.map.entities.push(pin);
            pin._location = locations[i];
            locations[i]._pin = pin;
        }

        if (!removePinsCalled) {
            recalculateMapViewport.bind(this)();
        }
    }


    var toggleClickToPin = function () {
        if (Microsoft.Maps.Events.hasHandler(this.map, "click")) {
            Microsoft.Maps.Events.removeHandler(this.clickToPinHandler);
            Microsoft.Maps.Events.removeHandler(this.clickToZoomHandler);
            Microsoft.Maps.Events.removeHandler(this.pinMouseMoveHandler);
            var mapElem = this.map.getRootElement();
            mapElem.style.cursor = "pointer";
        }
        else {
            this.clickToPinHandler = Microsoft.Maps.Events.addHandler(this.map, "click", addPinClickHandler.bind(this));
            this.pinMouseMoveHandler = Microsoft.Maps.Events.addHandler(this.map, "mousemove", pinMouseMoveHandler.bind(this));
        }
    }

    var toggleClickToZoom = function () {
        if (Microsoft.Maps.Events.hasHandler(this.map, "click")) {
            Microsoft.Maps.Events.removeHandler(this.clickToPinHandler);
            Microsoft.Maps.Events.removeHandler(this.clickToZoomHandler);
        }
        else {
            this.clickToZoomHandler = Microsoft.Maps.Events.addHandler(this.map, "click", addZoomClickHandler.bind(this));
        }
    }

    var searchHighwayExits = function (callback) {
        var bounds = this.map.getBounds();
        var context = this;
        //04/20/12 - Code to retrieve session credentials. Used on subsequent calls to REST services so that
        //            those hits on Microsoft's system will be non-billable. MJ KS2
        this.map.getCredentials(function (credentials) {
            bingMapsKey = credentials;
            var bboxString = "bbox(" + bounds.getSouth().toString() + "," + bounds.getWest().toString() + "," + bounds.getNorth().toString() + "," + bounds.getEast().toString() + ")";

            $.ajax({
                type: "GET",
                dataType: "jsonp",
                url: bingSpatialApiUrl + "f22876ec257b474b82fe2ffcb8393150/NavteqNA/NavteqPOIs",
                jsonp: "jsonp",
                data: {
                    key: bingMapsKey,
                    spatialFilter: bboxString,
                    $filter: "EntityTypeID Eq '9592'",
                    $format: "json"
                },
                context: context,
                success: function (json) {
                    var locations = getHighwayExitsCallback(json);
                    callback(locations);
                }
            });
        });
    }

    function SearchError(searchRequest) {
        alert("An error occurred in the searchManager.search method.");
    }

    var searchSuccess = function (searchResponse) {

        if (searchResponse &&
                searchResponse.searchResults &&
                searchResponse.searchResults.length > 0) {
            var locations = [];
            for (var i = 0; i < searchResponse.searchResults.length - 1; ++i) {
                var cp = searchResponse.searchResults[i].location;
                var name = searchResponse.searchResults[i].name;
                var address = searchResponse.searchResults[i].address;
                var city = searchResponse.searchResults[i].city;
                var state = searchResponse.searchResults[i].state;
                var zip = searchResponse.searchResults[i].postalCode;
                var description = name + "<br />" + address + "<br />" + city + ", " + state + "  " + zip;
                var location = new BingMaps.Location(cp.latitude, cp.longitude, description);

                locations.push(location);
            }
            if (locations == undefined) {
                alert("Error Message: \n\nPOI not found");
            } else {
                $.each(locations, function (index, value) {
                    value.setToDestClickCallback = function (location) {
                        setDestFromInfo(location.latitude, location.longitude, location.description);
                    };
                });
                genericMapping.addPins(locations, true, true);
            }
        }
    }

    // KB: Extend the API with a callback.
    var getEntities = function (location, searchText, callback) {

        if (!(location == null) && !(searchText == null)) {
            var searchRequest = {
                what: searchText,
                where: location.description,
                count: 10,
                callback: callback != null ? callback : searchSuccess, // KB: If callback if provided, delegate the response to the user provided callback. Use the default, otherwise.
                errorCallback: SearchError
            };
            this.searchManager.search(searchRequest);
        }
    }

    // KB: Extend the API with a callback.
    var createSearchManagerCallback = function (location, searchText, callback) {
        this.searchManager = new Microsoft.Maps.Search.SearchManager(this.map);
        return getEntities.bind(this, location, searchText, callback)();
    }

    var searchBusiness = function (location, searchText, callback) {
        var context = this;

        if (this.searchManager == null) {
            Microsoft.Maps.loadModule("Microsoft.Maps.Search", { callback: function () {
                createSearchManagerCallback.bind(context, location, searchText, callback)();
            }
            });
        }
        else {
            getEntities.bind(this, location, searchText, callback)();
        }
    }

    var calculateRoute = function (locations, callback) {
        var totalDistance = 0.0;
        var context = this;

        _eventHandlerMagic.init(callback);

        if (this.directionsManager == null) {
            Microsoft.Maps.loadModule("Microsoft.Maps.Directions", { callback: function () {
                var totalDistance = createDirectionsManagerCallback.bind(context, locations)();
                callback(totalDistance);
            }
            });
        }
        else {
            this.directionsManager.resetDirections({ removeAllWaypoints: true, resetRenderOptions: false, resetRequestOptions: false });
            var totalDistance = getDirections.bind(this, locations)();
            callback(totalDistance);
        }
    }

    var calculateDistance = function (locations, callback) {
        var context = this;
        //04/20/12 - Code to retrieve session credentials. Used on subsequent calls to REST services so that
        //            those hits on Microsoft's system will be non-billable. MJ KS2
        this.map.getCredentials(function (credentials) {
            bingMapsKey = credentials;

            var data = {
                key: bingMapsKey,
                distanceUnit: "mi"
            };

            for (var i = 0; i < locations.length; i++) {
                data["wp." + i.toString()] = locations[i].latitude.toString() + "," + locations[i].longitude.toString();
            }

            $.ajax({
                type: "GET",
                dataType: "jsonp",
                url: bingRoutesApiUrl + "Driving",
                jsonp: "jsonp",
                data: data,
                context: context,
                success: function (json) {
                    var totalDistance = calculateDistanceCallback.bind(context, json)();
                    callback(totalDistance);
                }
            });
        });
    }

    var removePins = function (locations) {
        for (var i = 0; i < locations.length; i++) {
            if (locations[i]._pin != null) {
                if (locations[i]._pin.infobox != null) {
                    this.map.entities.remove(locations[i]._pin.infobox);
                }
                this.map.entities.remove(locations[i]._pin);
            }
        }
    }

    var clearMap = function () {
        this.map.entities.clear();
        removePinsCalled = true;

        if (this.directionsManager != null) {
            this.directionsManager.resetDirections({ removeAllWaypoints: true, resetRenderOptions: false, resetRequestOptions: false });
        }
    }

    var getZoomLevel = function () {
        return this.map.getZoom();
    }
    //#endregion

    return {
        init: init,
        searchLocation: searchLocation,
        reverseGeocodeLocation: reverseGeocodeLocation,
        searchBusiness: searchBusiness,
        addPins: addPins,
        toggleClickToPin: toggleClickToPin,
        toggleClickToZoom: toggleClickToZoom,
        searchHighwayExits: searchHighwayExits,
        calculateRoute: calculateRoute,
        calculateDistance: calculateDistance,
        removePins: removePins,
        clearMap: clearMap,
        getZoomLevel: getZoomLevel
    }
} ();
