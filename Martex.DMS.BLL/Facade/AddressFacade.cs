using System;
using System.Collections.Generic;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Net;
using BingMapsRESTService.Common.JSON;
using System.Web;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class AddressFacade
    {
        /// <summary>
        /// BING API Key
        /// </summary>
        protected static readonly string BING_API_KEY = AppConfigRepository.GetValue(AppConfigConstants.BING_API_KEY);

        protected static readonly ILog logger = LogManager.GetLogger(typeof(AddressFacade));
        public const string ADD = "add";
        public const string EDIT = "edit";
        public const string DELETE = "delete";

        /// <summary>
        /// Saves the addresses.
        /// </summary>
        /// <param name="recordId">The record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="addresses">The addresses.</param>
        /// <param name="mode">The mode.</param>
        public void SaveAddresses(int recordId, string entityName, string userName, List<AddressEntity> addresses, string mode)
        {
            if (addresses != null)
            {
                foreach (AddressEntity address in addresses)
                {
                    logger.InfoFormat("'{0}'ing address [ {1} ]", mode, address.ID);
                    address.RecordID = recordId;
                    // Let us not create new Address type, country and stateprovince records.                            
                    address.AddressType = null;
                    address.Country = null;
                    address.StateProvince1 = null;
                    if (mode == ADD)
                    {
                        address.CreateBy = address.ModifyBy = userName;
                        address.CreateDate = address.ModifyDate = DateTime.Now;
                    }
                    else if (mode == EDIT)
                    {
                        address.ModifyBy = userName;
                        address.ModifyDate = DateTime.Now;
                    }
                    var addressRepository = new AddressRepository();
                    addressRepository.Save(address, entityName, mode == DELETE);
                }
            }

        }
        
        /// <summary>
        /// Gets the lat long.
        /// </summary>
        /// <param name="address">The address.</param>
        /// <param name="city">The city.</param>
        /// <param name="state">The state.</param>
        /// <param name="zip">The zip.</param>
        /// <param name="country">The country.</param>
        /// <returns></returns>
        public static LatitudeLongitude GetLatLong(string address, string city, string state, string zip, string country)
        {
            logger.InfoFormat("Querying BING with address [ {0}, {1}, {2}, {3}, {4} ]", address, city, state, zip, country);

            try
            {
                Uri geocodeRequest = new Uri(string.Format("http://dev.virtualearth.net/REST/v1/Locations?q={0}&key={1}", HttpUtility.UrlEncode(string.Join(" ", address, city, state, country, zip)), BING_API_KEY));

                WebClient wc = new WebClient();
                string responseAsString = wc.DownloadString(geocodeRequest);
                var response = JsonConvert.DeserializeObject<Response>(responseAsString);

                LatitudeLongitude latLong = new LatitudeLongitude();

                if (response != null && response.resourceSets != null && response.resourceSets.Count > 0)
                {
                    var resources = response.resourceSets[0].resources;
                    if (resources != null && resources.Count > 0)
                    {
                        logger.InfoFormat("Got results from BING");
                        var point = resources[0].point;
                        if (point != null)
                        {
                            latLong.Latitude = Convert.ToDecimal(point.coordinates[0]);
                            latLong.Longitude = Convert.ToDecimal(point.coordinates[1]);
                        }
                    }
                }

                #region OBSOLETE CODE
                /*GeocodeRequest geocodeRequest = new GeocodeRequest();

                // Set the credentials using a valid Bing Maps Key
                geocodeRequest.Credentials = new Credentials();
                geocodeRequest.Credentials.ApplicationId = BING_API_KEY;

                // Set the full address query
                geocodeRequest.Query = string.Join(" ", address, city, state, country, zip);

                // Set the options to only return high confidence results
                ConfidenceFilter[] filters = new ConfidenceFilter[1];
                filters[0] = new ConfidenceFilter();
                filters[0].MinimumConfidence = Confidence.High;

                GeocodeOptions geocodeOptions = new GeocodeOptions();
                geocodeOptions.Filters = filters;

                geocodeRequest.Options = geocodeOptions;

                // Make the geocode request
                GeocodeServiceClient geocodeService =
                new GeocodeServiceClient("BasicHttpBinding_IGeocodeService");
                GeocodeResponse geocodeResponse = geocodeService.Geocode(geocodeRequest);

                LatitudeLongitude latLong = new LatitudeLongitude();

                if (geocodeResponse.Results != null && geocodeResponse.Results.Length > 0)
                {
                    logger.InfoFormat("Got results from BING");
                    var result = geocodeResponse.Results[0];

                    // KB: To match the values returned by BING Maps official website, here is the precedence considered.
                    // InterpolationOffset < Interpolation < Parcel < Rooftop.
                    Dictionary<int, string> calculationMethodPrecendence = new Dictionary<int, string>();
                    calculationMethodPrecendence.Add(1, "Rooftop");
                    calculationMethodPrecendence.Add(2, "Parcel");
                    calculationMethodPrecendence.Add(3, "Interpolation");
                    calculationMethodPrecendence.Add(4, "InterpolationOffset");

                    var location = (from l in result.Locations
                                    join c in calculationMethodPrecendence on l.CalculationMethod equals c.Value
                                    orderby c.Key
                                    select l).FirstOrDefault();

                    if (location != null)
                    {
                        logger.InfoFormat("Calculation Method : {0} ", location.CalculationMethod);
                        latLong.Latitude = Convert.ToDecimal(location.Latitude);
                        latLong.Longitude = Convert.ToDecimal(location.Longitude);
                    }
                }*/

                #endregion

                logger.InfoFormat("Returning LatLong details : [ Lat = {0}, Long = {1} ]", latLong.Latitude.GetValueOrDefault(), latLong.Longitude.GetValueOrDefault());
                return latLong;
            }
            catch (Exception ex)
            {
                logger.Warn(ex.Message, ex);
                throw new DMSException("We are experiencing issues while querying BING API at the moment, please retry your request after sometime.");
            }


        }


        public static AddressDetails GetAddressDetailsByLatLong(decimal? latitude, decimal? longitude)
        {
            logger.InfoFormat("Querying BING with Lat : {0} Long : {1}", latitude, longitude);

            try
            {
                AddressDetails addressDetails = new AddressDetails();

                Uri geocodeRequest = new Uri(string.Format("http://dev.virtualearth.net/REST/v1/Locations/{0},{1}?key={2}", latitude,longitude, BING_API_KEY));

                WebClient wc = new WebClient();
                string responseAsString = wc.DownloadString(geocodeRequest);
                var response = JsonConvert.DeserializeObject<Response>(responseAsString);
                
                if (response != null && response.resourceSets != null && response.resourceSets.Count > 0)
                {
                    var resources = response.resourceSets[0].resources;
                    if (resources != null && resources.Count > 0)
                    {
                        logger.InfoFormat("Got results from BING");
                        CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                        var resultAddress = resources[0].address;

                        if (resultAddress != null)
                        {
                            addressDetails.Address = resultAddress.addressLine;
                            addressDetails.City = resultAddress.locality;
                            addressDetails.State = resultAddress.adminDistrict;
                            addressDetails.Country = resultAddress.countryRegion;
                            addressDetails.PostalCode = resultAddress.postalCode;

                            if (!(string.IsNullOrEmpty(addressDetails.State)))
                            {
                                StateProvince state = lookUpRepo.GetStateProvinceByAbbreviation(addressDetails.State);
                                if (state != null)
                                {
                                    Country country = lookUpRepo.GetCountry(state.CountryID.GetValueOrDefault());
                                    if (country != null)
                                    {
                                        addressDetails.CountryCode = country.ISOCode;
                                    }
                                }
                            }
                            else if (!(string.IsNullOrEmpty(addressDetails.Country)))
                            {
                                Country country = lookUpRepo.GetCountryByName(addressDetails.Country);
                                if (country != null)
                                {
                                    addressDetails.CountryCode = country.ISOCode;
                                }
                            }
                        }
                    }
                }

                #region OBSOLETE CODE

                /*ReverseGeocodeRequest geocodeRequest = new ReverseGeocodeRequest();

                // Set the credentials using a valid Bing Maps Key
                geocodeRequest.Credentials = new Credentials();
                geocodeRequest.Credentials.ApplicationId = BING_API_KEY;
                var location = new Location();
                location.Latitude = (double)latitude;
                location.Longitude = (double)longitude;
                // Set the full address query
                geocodeRequest.Location = location;



                // Set the options to only return high confidence results
                ConfidenceFilter[] filters = new ConfidenceFilter[1];
                filters[0] = new ConfidenceFilter();
                filters[0].MinimumConfidence = Confidence.High;

                GeocodeOptions geocodeOptions = new GeocodeOptions();
                geocodeOptions.Filters = filters;

                //geocodeRequest.Options = geocodeOptions;

                // Make the geocode request
                GeocodeServiceClient geocodeService =
                new GeocodeServiceClient("BasicHttpBinding_IGeocodeService");
                GeocodeResponse geocodeResponse = geocodeService.ReverseGeocode(geocodeRequest);

                AddressDetails addressDetails = new AddressDetails();

                if (geocodeResponse.Results != null && geocodeResponse.Results.Length > 0)
                {
                    logger.InfoFormat("Got results from BING");
                    var result = geocodeResponse.Results[0];

                    // KB: To match the values returned by BING Maps official website, here is the precedence considered.
                    // InterpolationOffset < Interpolation < Parcel < Rooftop.
                    Dictionary<int, string> calculationMethodPrecendence = new Dictionary<int, string>();
                    calculationMethodPrecendence.Add(1, "Rooftop");
                    calculationMethodPrecendence.Add(2, "Parcel");
                    calculationMethodPrecendence.Add(3, "Interpolation");
                    calculationMethodPrecendence.Add(4, "InterpolationOffset");
                    var resultAddress = result.Address;
                    CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                    if (resultAddress != null)
                    {
                        addressDetails.Address = resultAddress.AddressLine;
                        addressDetails.City = resultAddress.Locality;
                        addressDetails.State = resultAddress.AdminDistrict;
                        addressDetails.Country = resultAddress.CountryRegion;
                        addressDetails.PostalCode = resultAddress.PostalCode;

                        if (!(string.IsNullOrEmpty(addressDetails.State)))
                        {
                            StateProvince state = lookUpRepo.GetStateProvinceByAbbreviation(addressDetails.State);
                            if (state != null)
                            {
                                Country country = lookUpRepo.GetCountry(state.CountryID.GetValueOrDefault());
                                if (country != null)
                                {
                                    addressDetails.CountryCode = country.ISOCode;
                                }
                            }
                        }
                        else if (!(string.IsNullOrEmpty(addressDetails.Country)))
                        {
                            Country country = lookUpRepo.GetCountryByName(addressDetails.Country);
                            if (country != null)
                            {
                                addressDetails.CountryCode = country.ISOCode;
                            }
                        }
                    }

                }
                */

                #endregion

                //logger.InfoFormat("Returning LatLong details : [ Lat = {0}, Long = {1} ]", latLong.Latitude.GetValueOrDefault(), latLong.Longitude.GetValueOrDefault());
                return addressDetails;
            }
            catch (DMSException ex)
            {
                logger.Warn(ex.Message, ex);
                throw ex;
            }
            catch (Exception ex)
            {
                logger.Warn(ex.Message, ex);
                throw new DMSException("We are experiencing issues while querying BING API at the moment, please retry your request after sometime.");
            }


        }


        // Lakshmi - Hagerty Integration
        /// <summary>
        /// Get the name of state abbreviation. 
        /// </summary>
        /// <param name="stateID">State ID</param>
        public string GetStateAbbreviation(int? stateID)
        {
            AddressRepository addRepository = new AddressRepository();
            return addRepository.GetStateAbbreviation(stateID);
        }
    }

    /// <summary>
    /// Class that encapsulates latitude and longitude values.
    /// </summary>
    public class LatitudeLongitude
    {
        #region Public Methods
        /// <summary>
        /// Gets or sets the latitude.
        /// </summary>
        /// <value>
        /// The latitude.
        /// </value>
        public decimal? Latitude { get; set; }
        /// <summary>
        /// Gets or sets the longitude.
        /// </summary>
        /// <value>
        /// The longitude.
        /// </value>
        public decimal? Longitude { get; set; }
        #endregion
    }

    public class AddressDetails
    {
        public string Address { get; set; }
        public string City { get; set; }
        public string State { get; set; }
        public string Country { get; set; }
        public string CountryCode { get; set; }
        public string PostalCode { get; set; }
    }
}
