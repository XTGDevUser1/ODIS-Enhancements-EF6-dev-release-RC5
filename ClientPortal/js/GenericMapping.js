// Date : 05-Nov-2012
// Changed entire API
var genericMapping = function () {

    var provider;

    var init = function (mapProvider, mapDiv, directionsDiv) {
        this.provider = new mapProvider();
        this.provider.init(mapDiv, directionsDiv);
    }

    var searchLocation = function (searchText, callback) {
        removePinsCalled = false;
        this.provider.searchLocation(searchText, callback);
    }

    var reverseGeocodeLocation = function (latitude, longitude, callback) {
        removePinsCalled = false;
        this.provider.reverseGeocodeLocation(latitude, longitude, callback);
    }

    // KB: Extend the API with a callback.
    var searchBusiness = function (location, searchText, callback) {
        removePinsCalled = false;
        this.provider.searchBusiness(location, searchText, callback);
    }

    //Sanghi :
    var addPins = function (locations, hasInfobox, hasSetDestination, infoBoxOptions) {
        this.provider.addPins(locations, hasInfobox, hasSetDestination, infoBoxOptions);
    }

    var toggleClickToPin = function () {
        this.provider.toggleClickToPin();
    }

    var toggleClickToZoom = function () {
        this.provider.toggleClickToZoom();
    }

    var searchHighwayExits = function (callback) {
        this.provider.searchHighwayExits(callback);
    }

    var calculateRoute = function (locations, callback) {
        this.provider.calculateRoute(locations, callback);
    }

    var calculateDistance = function (locations, callback) {
        this.provider.calculateDistance(locations, callback);
    }

    var removePins = function (locations) {
        this.provider.removePins(locations);
    }

    var clearMap = function () {
        this.provider.clearMap();
    }

    var getZoomLevel = function () {
        return this.provider.getZoomLevel();
    }

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
