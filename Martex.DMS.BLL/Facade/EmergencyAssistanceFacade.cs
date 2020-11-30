using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Common;
using System.Xml;
using Martex.DMS.BLL.TechnoCom;
using System.Xml.Serialization;
using System.IO;
using LookupUS = Martex.DMS.BLL.PSAP_LookupUS;
using Martex.DMS.BLL.PSAP_LookupUS;
using NearestUS = Martex.DMS.BLL.PSAPNearestUS;
using Martex.DMS.BLL.PSAPNearestUS;
using System.ServiceModel;
using System.Web.Hosting;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Extensions;
using System.Transactions;
using Martex.DMS.DAL.Common;
using log4net;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    public class EmergencyAssistanceFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(EmergencyAssistanceFacade));

        #region Private Members
        private PhoneLocationResultType PhoneLocationResult { get; set; }
        private string PhoneLocationResultTypeMessage { get; set; }
        #endregion

        #region Public Methods
        /// <summary>
        /// Gets the case for the given case ID
        /// </summary>
        /// <param name="caseID">The case ID.</param>
        /// <returns></returns>
        public EmergencyAssistanceModel GetEmergencyAssistance(int inBoundCallID, string callbackNumber, int caseID, int serviceRequestID)
        {
            //Retrieving Case Details From Case
            EmergencyAssistanceRepository emergencyAssistanceRepository = new EmergencyAssistanceRepository();
            logger.InfoFormat("Trying to retrieve information from Emergency Assistance by passing InBoundCall ID {0}", inBoundCallID);
            EmergencyAssistance emergencyAssistance = emergencyAssistanceRepository.GetEmergencyAssistance(inBoundCallID);
            logger.Info("Retrieving Finished");

            //Assign retrieve model into EmergencyAssistanceModel
            EmergencyAssistanceModel model = new EmergencyAssistanceModel();
            model.EmergencyAssistance = emergencyAssistance;
            model.CallBackNumber = callbackNumber;
            model.EmergencyAssistance.ContactPhoneNumber = callbackNumber;
            model.SearchLocation = emergencyAssistance.Address;
            model.ResultType = PhoneLocationResultType.NO_RECORDS_FOUND;
            model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;

            // RC : 29.07.2013

            // Rank : 1 Case 1 
            // When there is no Service Request as well as Emergency Record look into Case Phone Location
            if (serviceRequestID <= 0 && emergencyAssistance.ID <= 0)
            {
                logger.Info("Service Request Details and EA are not available so going by Case Phone Location");
                CasePhoneLocation casePhoneLocation = null;
                CasePhoneLocationFacade casePhoneLocationFacade = new CasePhoneLocationFacade();
                logger.InfoFormat("Trying to look into Case Phone Location by passing CaseID {0} or InBoundCall ID {1}", caseID, inBoundCallID);
                casePhoneLocation = casePhoneLocationFacade.Get(caseID, inBoundCallID);
                if (casePhoneLocation != null)
                {
                    logger.InfoFormat("Record Found which means we have Latitude and Longtitude to Plot the Map. Latitude {0} Longitude {1}", casePhoneLocation.CivicLatitude, casePhoneLocation.CivicLongitude);
                    model.EmergencyAssistance.Latitude = casePhoneLocation.CivicLatitude;
                    model.EmergencyAssistance.Longitude = casePhoneLocation.CivicLongitude;
                    model.ResultType = PhoneLocationResultType.SUCCESS;
                    model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
                }
            }
            // Rank 2 Case 2 when there is an Emergency Assistance Record
            else if (emergencyAssistance.ID > 0)
            {
                logger.InfoFormat("Emergency Assistance record found so going by EA ID {0}", emergencyAssistance.ID);
                logger.Info("Emergency Assistance record found so Check to see Latitude and Longitude values");
                if (!model.EmergencyAssistance.Latitude.HasValue && !model.EmergencyAssistance.Longitude.HasValue)
                {
                    logger.Info("Emergency Assistance record found but location information is not found");
                    if (serviceRequestID > 0)
                    {
                        logger.Info("Trying to get the details from SR");
                        ServiceRequest srDetails = new ServiceRequestRepository().GetById(serviceRequestID);
                        if (srDetails != null)
                        {
                            logger.InfoFormat("Found Service Request Details so assigning values for Latitude {0} Longitude {1} Address {2} ", srDetails.ServiceLocationLatitude, srDetails.ServiceLocationLongitude, srDetails.ServiceLocationAddress);
                            model.EmergencyAssistance.Latitude = srDetails.ServiceLocationLatitude;
                            model.EmergencyAssistance.Longitude = srDetails.ServiceLocationLongitude;
                            model.EmergencyAssistance.Address = srDetails.ServiceLocationAddress;
                            model.SearchLocation = srDetails.ServiceLocationAddress;

                            //Retrieve Details from Case
                            logger.InfoFormat("Trying to Retrieve Case Information for CaseID {0}", srDetails.CaseID);
                            Case caseDetails = new CaseRepository().GetCaseById(srDetails.CaseID);
                            if (caseDetails != null)
                            {
                                model.EmergencyAssistance.MemberFirstName = caseDetails.ContactFirstName;
                                model.EmergencyAssistance.MemberLastName = caseDetails.ContactLastName;
                                model.EmergencyAssistance.VehicleTypeID = caseDetails.VehicleTypeID;
                                model.EmergencyAssistance.VehicleYear = caseDetails.VehicleYear;
                                model.EmergencyAssistance.VehicleMake = string.IsNullOrEmpty(caseDetails.VehicleMakeOther) ? caseDetails.VehicleMake : "Other";
                                model.EmergencyAssistance.VehicleMakeOther = caseDetails.VehicleMakeOther;
                                model.EmergencyAssistance.VehicleModel = string.IsNullOrEmpty(caseDetails.VehicleModelOther) ? caseDetails.VehicleModel : "Other";
                                model.EmergencyAssistance.VehicleModelOther = caseDetails.VehicleModelOther;
                                model.EmergencyAssistance.VehicleColor = caseDetails.VehicleColor;
                                model.EmergencyAssistance.VehicleLicenseState = caseDetails.VehicleLicenseState;
                                model.EmergencyAssistance.VehicleLicenseStateCountryID = caseDetails.VehicleLicenseCountryID;
                                model.EmergencyAssistance.VehicleLicenseNumber = caseDetails.VehicleLicenseNumber;
                            }
                            model.ResultType = PhoneLocationResultType.SUCCESS;
                            model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
                        }
                        else
                        {
                            logger.Info("SR information not found so further lookup is not required");

                        }
                    }
                }
                else
                {
                    model.ResultType = PhoneLocationResultType.SUCCESS;
                    model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
                    logger.Info("Emergency Assistance record found location information is found no further lookup required");
                }

            }
            // Rank 3 Case 3 when there is a SR
            else if (serviceRequestID > 0)
            {
                logger.Info("Trying to get the details from SR");
                ServiceRequest srDetails = new ServiceRequestRepository().GetById(serviceRequestID);
                if (srDetails != null)
                {
                    logger.InfoFormat("Found Service Request Details so assigning values for Latitude {0} Longitude {1} Address {2} ", srDetails.ServiceLocationLatitude, srDetails.ServiceLocationLongitude, srDetails.ServiceLocationAddress);
                    model.EmergencyAssistance.Latitude = srDetails.ServiceLocationLatitude;
                    model.EmergencyAssistance.Longitude = srDetails.ServiceLocationLongitude;
                    model.EmergencyAssistance.Address = srDetails.ServiceLocationAddress;
                    model.SearchLocation = srDetails.ServiceLocationAddress;

                    //Retrieve Details from Case
                    logger.InfoFormat("Trying to Retrieve Case Information for CaseID {0}", srDetails.CaseID);
                    Case caseDetails = new CaseRepository().GetCaseById(srDetails.CaseID);
                    if (caseDetails != null)
                    {
                        model.EmergencyAssistance.MemberFirstName = caseDetails.ContactFirstName;
                        model.EmergencyAssistance.MemberLastName = caseDetails.ContactLastName;
                        model.EmergencyAssistance.VehicleTypeID = caseDetails.VehicleTypeID;
                        model.EmergencyAssistance.VehicleYear = caseDetails.VehicleYear;
                        model.EmergencyAssistance.VehicleMake = string.IsNullOrEmpty(caseDetails.VehicleMakeOther) ? caseDetails.VehicleMake : "Other";
                        model.EmergencyAssistance.VehicleMakeOther = caseDetails.VehicleMakeOther;
                        model.EmergencyAssistance.VehicleModel = string.IsNullOrEmpty(caseDetails.VehicleModelOther) ? caseDetails.VehicleModel : "Other";
                        model.EmergencyAssistance.VehicleModelOther = caseDetails.VehicleModelOther;
                        model.EmergencyAssistance.VehicleColor = caseDetails.VehicleColor;
                        model.EmergencyAssistance.VehicleLicenseState = caseDetails.VehicleLicenseState;
                        model.EmergencyAssistance.VehicleLicenseStateCountryID = caseDetails.VehicleLicenseCountryID;
                        model.EmergencyAssistance.VehicleLicenseNumber = caseDetails.VehicleLicenseNumber;
                    }
                    model.ResultType = PhoneLocationResultType.SUCCESS;
                    model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
                }
                else
                {
                    logger.Info("SR information not found so further lookup is not required");

                }
            }

            //// Check to see if the user is visiting this tab after creating a new request or opening an existing request that doesn't have an emergency record yet.
            //if (serviceRequestID > 0 && emergencyAssistance.ID <= 0)
            //{
            //    logger.InfoFormat("Emergency Assistance record not found so going by Service Request ID {0}", serviceRequestID);
            //    ServiceRequest srDetails = new ServiceRequestRepository().GetById(serviceRequestID);
            //    if (srDetails != null)
            //    {
            //        logger.InfoFormat("Found Service Request Details so assigning values for Latitude {0} Longitude {1} Address {2} ", srDetails.ServiceLocationLatitude, srDetails.ServiceLocationLongitude, srDetails.ServiceLocationAddress);
            //        model.EmergencyAssistance.Latitude = srDetails.ServiceLocationLatitude;
            //        model.EmergencyAssistance.Longitude = srDetails.ServiceLocationLongitude;
            //        model.EmergencyAssistance.Address = srDetails.ServiceLocationAddress;

            //        //Retrieve Details from Case
            //        logger.InfoFormat("Trying to Retrieve Case Information for CaseID {0}", srDetails.CaseID);
            //        Case caseDetails = new CaseRepository().GetCaseById(srDetails.CaseID);
            //        if (caseDetails != null)
            //        {
            //            model.EmergencyAssistance.MemberFirstName = caseDetails.ContactFirstName;
            //            model.EmergencyAssistance.MemberLastName = caseDetails.ContactLastName;
            //            model.EmergencyAssistance.VehicleTypeID = caseDetails.VehicleTypeID;
            //            model.EmergencyAssistance.VehicleYear = caseDetails.VehicleYear;
            //            model.EmergencyAssistance.VehicleMake = string.IsNullOrEmpty(caseDetails.VehicleMakeOther) ? caseDetails.VehicleMake : "Other";
            //            model.EmergencyAssistance.VehicleMakeOther = caseDetails.VehicleMakeOther;
            //            model.EmergencyAssistance.VehicleModel = string.IsNullOrEmpty(caseDetails.VehicleModelOther) ? caseDetails.VehicleModel : "Other";
            //            model.EmergencyAssistance.VehicleModelOther = caseDetails.VehicleModelOther;
            //            model.EmergencyAssistance.VehicleColor = caseDetails.VehicleColor;
            //            model.EmergencyAssistance.VehicleLicenseState = caseDetails.VehicleLicenseState;
            //            model.EmergencyAssistance.VehicleLicenseStateCountryID = caseDetails.VehicleLicenseCountryID;
            //            model.EmergencyAssistance.VehicleLicenseNumber = caseDetails.VehicleLicenseNumber;
            //        }
            //        model.ResultType = PhoneLocationResultType.SUCCESS;
            //        model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
            //    }

            //}
            //else // SR is not created yet and there is no emergency record too.
            //{
            //    logger.Info("Service Request Details are not available so going by Case Phone Location");
            //    CasePhoneLocation casePhoneLocation = null;
            //    CasePhoneLocationFacade casePhoneLocationFacade = new CasePhoneLocationFacade();
            //    logger.InfoFormat("Trying to look into Case Phone Location by passing CaseID {0} or InBoundCall ID {1}", caseID, inBoundCallID);
            //    casePhoneLocation = casePhoneLocationFacade.Get(caseID, inBoundCallID);
            //    if (casePhoneLocation != null)
            //    {
            //        logger.InfoFormat("Record Found which means we have Latitude and Longtitude to Plot the Map. Latitude {0} Longitude {1}", casePhoneLocation.CivicLatitude, casePhoneLocation.CivicLongitude);
            //        model.EmergencyAssistance.Latitude = casePhoneLocation.CivicLatitude;
            //        model.EmergencyAssistance.Longitude = casePhoneLocation.CivicLongitude;
            //        model.ResultType = PhoneLocationResultType.SUCCESS;
            //        model.ResultTypeMessage = this.PhoneLocationResultTypeMessage;
            //    }
            //}
            //Model for Contact Log and Comments
            ContactLogFacade contactLogFacade = new ContactLogFacade();
            model.ContactLog = new ContactLog();
            model.Comment = new CommentFacade().Get(model.EmergencyAssistance.ID, EntityNames.EMERGENCY_ASSISTANCE).FirstOrDefault();
            model.PreviousCallList = contactLogFacade.GetPreviousCallList(model.EmergencyAssistance.ID, model.ContactLog.ID);
            model.ContactInsertRequired = true;
            return model;
        }
        #endregion

        #region Helper methods for Conversion

        /// <summary>
        /// Populates the data from emergency assistance to crea.
        /// </summary>
        /// <param name="casePhoneLocation">The case phone location.</param>
        /// <param name="emergencyAssistance">The emergency assistance.</param>
        /// <returns></returns>
        private void PopulateDataFromEmergencyAssistance(CasePhoneLocation casePhoneLocation, EmergencyAssistance emergencyAssistance)
        {
            if (casePhoneLocation == null)
            {
                return;
            }
            emergencyAssistance.Address = casePhoneLocation.CivicStreet + " " + casePhoneLocation.CivicCounty;
            emergencyAssistance.Latitude = casePhoneLocation.CivicLatitude;
            emergencyAssistance.Longitude = casePhoneLocation.CivicLongitude;
            emergencyAssistance.CrossStreet1 = casePhoneLocation.IntersectionStreet1;
            emergencyAssistance.CrossStreet2 = casePhoneLocation.IntersectionStreet2;

            emergencyAssistance.ContactPhoneNumber = casePhoneLocation.PhoneNumber;

            emergencyAssistance.StateProvince = casePhoneLocation.CivicState;
            emergencyAssistance.PostalCode = casePhoneLocation.CivicZip;
            emergencyAssistance.Country = casePhoneLocation.CivicCountry;
            return;
        }
        #endregion

        #region Web Service
        /// <summary>
        /// Get the phone location from the webservice
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public CasePhoneLocation WSGetPhoneLocation(string phoneNumber, int caseId)
        {
            if (string.IsNullOrEmpty(phoneNumber))
            {
                return null;
            }
            //Call Database by passing the case id into Case Phone Location

            CasePhoneLocation phoneLocation = new CasePhoneLocationFacade().Get(caseId);

            if (phoneLocation != null) // Data Exists do not call web service.
            {
                this.PhoneLocationResult = PhoneLocationResultType.SUCCESS;
                this.PhoneLocationResultTypeMessage = string.Empty;
                return phoneLocation;
            }
            //Call Web Service
            const string PHONE_NUMBER_LOCATION_HAS_NOT_BEEN_REQUESTED = "There is no location information for this phone number.";
            const string PHONE_NUMBER_LOCATION_COULD_NOT_BE_DETERMINED = "Phone number location could not be determined.";

            try
            {
                string locationRequestServiceGUID = AppConfigRepository.GetValue(AppConfigConstants.GET_LOCATION_RESULT_SERVICE_GUID);

                EndpointAddress WSAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.GET_LOCATION_RESULT_SERVICE_URI));
                BasicHttpBinding WSBinding = new BasicHttpBinding();

                LocationRequestSoapClient wsClient = new LocationRequestSoapClient(WSBinding, WSAddress);
                /* Enable the following call when the web service is accessible */
                /**REMOVE COUNTRY CODE BEFORE SENDING TO WEB SERVICE TO LOOKUP**/
                var startIndex = phoneNumber.IndexOf(" ");
                if (startIndex > 0)
                {
                    phoneNumber = phoneNumber.Substring(startIndex + 1);
                }

                //Remove Formatting From Phone Number
                string[] spacesX = phoneNumber.Split('x');
                string unformattedPhoneNumber = string.Empty;
                if (spacesX.Length > 1)
                {
                    unformattedPhoneNumber = spacesX[0].ToString();
                }
                else
                {
                    unformattedPhoneNumber = phoneNumber;
                }

                XmlNode xmlResult = wsClient.GetLocationRequestResult(locationRequestServiceGUID, unformattedPhoneNumber);
                string xml = xmlResult.InnerXml;
                /* KB: The following is a placeholder implementation that reads the xml and deserializes it to locationresponse */

                //string PHONE_LOCATION_RESULT_XML = HostingEnvironment.MapPath("~/PhoneLocationResult_Temp/GetLocationRequestResult.xml");
                //string xml = string.Empty;
                //using (StreamReader reader = new StreamReader(PHONE_LOCATION_RESULT_XML))
                //{
                //    xml = reader.ReadToEnd();
                //}
                if (!xml.Contains("<locationResponse>"))
                {
                    xml = string.Format("<locationResponse>{0}</locationResponse>", xml);
                }
                XmlSerializer ser = new XmlSerializer(typeof(locationResponse));
                //RA - Get Error on following line!
                locationResponse obj = (locationResponse)ser.Deserialize(new StringReader(xml));

                phoneLocation = GetCasePhoneLocationFromWSResponse(obj, phoneNumber);


                //Insert Data into data base
                if (phoneLocation != null)
                {
                    phoneLocation.CaseID = caseId == 0 ? (int?)null : caseId;
                    phoneLocation.PhoneNumber = phoneNumber;
                    //new CasePhoneLocationFacade().Save(phoneLocation);
                    if (phoneLocation.CivicLatitude != null && phoneLocation.CivicLongitude != null)
                    {
                        this.PhoneLocationResult = PhoneLocationResultType.SUCCESS;
                        this.PhoneLocationResultTypeMessage = string.Empty;
                    }
                    else
                    {
                        this.PhoneLocationResult = PhoneLocationResultType.ENTRY_FOUND_NO_COORDINATES;
                        this.PhoneLocationResultTypeMessage = PHONE_NUMBER_LOCATION_COULD_NOT_BE_DETERMINED;
                    }
                }
                else
                {
                    this.PhoneLocationResult = PhoneLocationResultType.NO_RECORDS_FOUND;
                    this.PhoneLocationResultTypeMessage = PHONE_NUMBER_LOCATION_HAS_NOT_BEEN_REQUESTED;
                }
            }
            catch (Exception ex)
            {
                //TODO: See if we can present the exception in a better way
                logger.Warn(ex.Message, ex);
                this.PhoneLocationResult = PhoneLocationResultType.NO_RECORDS_FOUND;
                this.PhoneLocationResultTypeMessage = PHONE_NUMBER_LOCATION_HAS_NOT_BEEN_REQUESTED;
                return phoneLocation;
            }
            return phoneLocation;
        }

        #region Helper Method for Phone Location
        /// <summary>
        /// Gets the case phone location from WS response.
        /// </summary>
        /// <param name="response">The response.</param>
        /// <param name="phoneNumber">The phone number.</param>
        /// <returns></returns>
        private CasePhoneLocation GetCasePhoneLocationFromWSResponse(locationResponse response, string phoneNumber)
        {
            CasePhoneLocation casePhoneLocation = null;
            if (response.Items != null && response.Items.Count() == 2)
            {

                // Get the header values
                locationResponseResponseHeader header = response.Items[0] as locationResponseResponseHeader;

                int rowReturned = 0;
                int.TryParse(header.rowsReturned, out rowReturned);
                if (rowReturned > 0)
                {
                    casePhoneLocation = new CasePhoneLocation();
                    casePhoneLocation.PhoneNumber = phoneNumber;
                    casePhoneLocation.IsSMSAvailable = Convert.ToBoolean(header.smsAvailable);
                    // Process the details
                    locationResponseResponseDetail detail = response.Items[1] as locationResponseResponseDetail;

                    if (!string.IsNullOrEmpty(detail.requestTime))
                    {
                        casePhoneLocation.LocationDate = DateTime.Parse(detail.requestTime);
                    }
                    if (!string.IsNullOrEmpty(detail.locationQualifier))
                    {
                        casePhoneLocation.LocationAccuracy = detail.locationQualifier;
                    }
                    if (detail.geoAddress != null)
                    {
                        if (!string.IsNullOrEmpty(detail.geoAddress.ElementAt(0).accuracy))
                        {
                            casePhoneLocation.GeoAccuracy = int.Parse(detail.geoAddress.ElementAt(0).accuracy);
                        }
                    }
                    locationResponseResponseDetailCivicAddress[] civicAddresses = detail.civicAddress;
                    decimal dVal = 0;
                    int iVal = 0;
                    if (civicAddresses.Length > 0)
                    {
                        locationResponseResponseDetailCivicAddress civicAddress = civicAddresses[0];

                        if (!string.IsNullOrEmpty(civicAddress.latitude))
                        {
                            decimal.TryParse(civicAddress.latitude, out dVal);
                            casePhoneLocation.CivicLatitude = dVal;
                        }

                        dVal = 0;
                        if (!string.IsNullOrEmpty(civicAddress.longitude))
                        {
                            decimal.TryParse(civicAddress.longitude, out dVal);
                            casePhoneLocation.CivicLongitude = dVal;
                        }

                        iVal = 0;
                        if (!string.IsNullOrEmpty(civicAddress.distance))
                        {
                            int.TryParse(civicAddress.distance, out iVal);
                            casePhoneLocation.CivicDistance = iVal;
                        }

                        casePhoneLocation.CivicDirection = civicAddress.direction;

                        casePhoneLocation.CivicStreet = civicAddress.streetAddress;
                        casePhoneLocation.CivicCity = civicAddress.city;
                        casePhoneLocation.CivicCountry = civicAddress.country;
                        casePhoneLocation.CivicState = civicAddress.state;
                        casePhoneLocation.CivicZip = civicAddress.zip;
                    }

                    locationResponseResponseDetailExtAddress[] extAddresses = detail.extAddress;
                    if (extAddresses.Length > 0)
                    {
                        locationResponseResponseDetailExtAddress extAddress = extAddresses[0];
                        if (extAddress.nearCrossStreet.Length > 0)
                        {
                            locationResponseResponseDetailExtAddressNearCrossStreet nearCrossStreet = extAddress.nearCrossStreet[0];
                            dVal = 0;
                            if (!string.IsNullOrEmpty(nearCrossStreet.latitude))
                            {
                                decimal.TryParse(nearCrossStreet.latitude, out dVal);
                                casePhoneLocation.CrossLatitude = dVal;
                            }

                            dVal = 0;
                            if (!string.IsNullOrEmpty(nearCrossStreet.longitude))
                            {
                                decimal.TryParse(nearCrossStreet.longitude, out dVal);
                                casePhoneLocation.CrossLongitude = dVal;
                            }

                            iVal = 0;
                            if (!string.IsNullOrEmpty(nearCrossStreet.distance))
                            {
                                int.TryParse(nearCrossStreet.distance, out iVal);
                                casePhoneLocation.CrossDistance = iVal;
                            }

                            casePhoneLocation.CrossDirection = nearCrossStreet.direction;
                            casePhoneLocation.CrossStreet = nearCrossStreet.street1;
                        }
                        if (extAddress.nearIntersection.Length > 0)
                        {
                            locationResponseResponseDetailExtAddressNearIntersection nearIntersection = extAddress.nearIntersection[0];

                            dVal = 0;
                            if (!string.IsNullOrEmpty(nearIntersection.latitude))
                            {
                                decimal.TryParse(nearIntersection.latitude, out dVal);
                                casePhoneLocation.IntersectionLatitude = dVal;
                            }

                            dVal = 0;
                            if (!string.IsNullOrEmpty(nearIntersection.longitude))
                            {
                                decimal.TryParse(nearIntersection.longitude, out dVal);
                                casePhoneLocation.IntersectionLongitude = dVal;
                            }

                            iVal = 0;
                            if (!string.IsNullOrEmpty(nearIntersection.distance))
                            {
                                int.TryParse(nearIntersection.distance, out iVal);
                                casePhoneLocation.IntersectionDistance = iVal;
                            }

                            casePhoneLocation.IntersectionDirection = nearIntersection.direction;
                            casePhoneLocation.IntersectionStreet1 = nearIntersection.street1;
                            casePhoneLocation.IntersectionStreet2 = nearIntersection.street2;
                        }

                    }
                }
            }
            return casePhoneLocation;
        }
        #endregion

        /// <summary>
        /// Call PSAPLookupUS web service
        /// </summary>
        /// <param name="latitude">The latitude.</param>
        /// <param name="longitude">The longitude.</param>
        /// <returns></returns>
        private ContactEmergencyAssistance WSGetPSAPLookupUS(string latitude, string longitude)
        {
            ContactEmergencyAssistance result = new ContactEmergencyAssistance();
            result.ResultFound = false;
            result.IsError = false;
            try
            {
                /*EndpointAddress WSAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.PSAP_Lookup_US_URI));
            BasicHttpBinding WSBinding = new BasicHttpBinding(BasicHttpSecurityMode.TransportCredentialOnly);
            */
                //EOLS_PSAPLookupUSClient client = new EOLS_PSAPLookupUSClient(WSBinding, WSAddress);
                EOLS_PSAPLookupUSClient client = new EOLS_PSAPLookupUSClient();
                client.Endpoint.Address = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.PSAP_Lookup_US_URI));


                client.ClientCredentials.UserName.UserName = AppConfigRepository.GetValue(AppConfigConstants.PSAP_Username);
                client.ClientCredentials.UserName.Password = AppConfigRepository.GetValue(AppConfigConstants.PSAP_Password);

                LookupUS.InputRow[] inputs = new LookupUS.InputRow[1];
                inputs[0] = new LookupUS.InputRow();

                inputs[0].Latitude = latitude;
                inputs[0].Longitude = longitude;

                LookupUS.OutputRow[] outputs = client.EOLS_PSAPLookupUS(null, inputs);
                if (outputs.Length > 0 && outputs[0].Status != "F")
                {
                    result.AgencyName = outputs[0].Agency;
                    result.OperatorPhoneNumber = outputs[0].OperatorPhone;
                    result.ResultFound = true;
                    result.AdditonalInformation = string.Empty;
                }

                //Call Additional Service if no data found ! then   
            }
            catch (Exception ex)
            {
                result.IsError = true;
                result.ErrorMessage = ex.Message;
                logger.Error(ex);
            }

            return result;
        }

        /// <summary>
        /// Call PSAPNearestUS web service
        /// </summary>
        /// <param name="latitude">The latitude.</param>
        /// <param name="longitude">The longitude.</param>
        /// <returns></returns>
        private ContactEmergencyAssistance WSPSAP_Nearest_US(string latitude, string longitude)
        {
            //PSAPNearestUS.
            ContactEmergencyAssistance result = new ContactEmergencyAssistance();
            result.ResultFound = false;
            result.IsError = false;
            try
            {
                EOLS_PSAP_Nearest_USClient client = new EOLS_PSAP_Nearest_USClient();
                client.Endpoint.Address = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.PSAP_Nearest_US_URI));

                client.ClientCredentials.UserName.UserName = AppConfigRepository.GetValue(AppConfigConstants.PSAP_Username);
                client.ClientCredentials.UserName.Password = AppConfigRepository.GetValue(AppConfigConstants.PSAP_Password);

                NearestUS.InputRow[] inputs = new NearestUS.InputRow[1];
                inputs[0] = new NearestUS.InputRow();

                inputs[0].Latitude = latitude;
                inputs[0].Longitude = longitude;

                NearestUS.OutputRow[] outputs = client.EOLS_PSAP_Nearest_US(null, inputs);
                if (outputs.Length > 0 && outputs[0].Status != "F")
                {
                    result.AgencyName = outputs[0].Agency;
                    result.OperatorPhoneNumber = outputs[0].OperatorPhone;

                    result.AdditonalInformation = "Location is outside the agency jurisdiction.";
                    result.ResultFound = true;
                }
                //Call Additional Service if no data found ! then 
            }
            catch (Exception ex)
            {
                result.IsError = true;
                result.ErrorMessage = ex.Message;
                logger.Error(ex);
            }

            return result;

        }

        /// <summary>
        /// Call the PSAP web services in the following order - PSAPLookupUS followed by PSAPNearestUS
        /// </summary>
        /// <param name="latitude">The latitude.</param>
        /// <param name="longitude">The longitude.</param>
        /// <returns></returns>
        public ContactEmergencyAssistance WSGetPSAPNumber(string latitude, string longitude)
        {
            ContactEmergencyAssistance result = WSGetPSAPLookupUS(latitude, longitude);
            if (!result.ResultFound)
            {
                return WSPSAP_Nearest_US(latitude, longitude);
            }
            return result;
        }
        #endregion


        /// <summary>
        /// Creates an instance emergency assistance.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="createdBy">The created by.</param>
        /// <param name="eventLog">The event log.</param>
        /// <returns></returns>
        public PreviousCallList SaveEmergencyAssistance(EmergencyAssistanceModel model, string createdBy, string eventSource, string sessionID)
        {
            Dictionary<string, string> descriptionForContactLog = new Dictionary<string, string>();
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            eventDetails.Add("CaseID", model.EmergencyAssistance.CaseID.ToString());
            eventDetails.Add("MemberFirstName", model.EmergencyAssistance.MemberFirstName);
            eventDetails.Add("MemberLastName", model.EmergencyAssistance.MemberLastName);
            eventDetails.Add("Longitude", model.EmergencyAssistance.Longitude.ToString());
            eventDetails.Add("Latitude", model.EmergencyAssistance.Latitude.ToString());
            eventDetails.Add("Address", model.EmergencyAssistance.Address);
            eventDetails.Add("CrossStreet1", model.EmergencyAssistance.CrossStreet1);
            eventDetails.Add("CrossStreet2", model.EmergencyAssistance.CrossStreet2);
            eventDetails.Add("StateProvince", model.EmergencyAssistance.StateProvince);
            eventDetails.Add("PostalCode", model.EmergencyAssistance.PostalCode);
            eventDetails.Add("Country", model.EmergencyAssistance.Country);
            eventDetails.Add("ANIPhoneNumber", model.EmergencyAssistance.ANIPhoneNumber);
            eventDetails.Add("ContactPhoneNumber", model.EmergencyAssistance.ContactPhoneNumber);
            eventDetails.Add("VehicleTypeID", model.EmergencyAssistance.VehicleTypeID.ToString());
            eventDetails.Add("VehicleYear", model.EmergencyAssistance.VehicleYear);
            eventDetails.Add("VehicleMake", model.EmergencyAssistance.VehicleMake);
            eventDetails.Add("VehicleMakeOther", model.EmergencyAssistance.VehicleMakeOther);
            eventDetails.Add("VehicleModel", model.EmergencyAssistance.VehicleModel);
            eventDetails.Add("VehicleModelOther", model.EmergencyAssistance.VehicleModelOther);
            eventDetails.Add("VehicleColor", model.EmergencyAssistance.VehicleColor);
            eventDetails.Add("CreateBy", model.EmergencyAssistance.CreateBy);
            eventDetails.Add("CreateDate", model.EmergencyAssistance.CreateDate.ToString());


            descriptionForContactLog.Add("FirstName", model.EmergencyAssistance.MemberFirstName);
            descriptionForContactLog.Add("LastName", model.EmergencyAssistance.MemberLastName);
            descriptionForContactLog.Add("CallbackNumber", model.CallBackNumber);
            descriptionForContactLog.Add("Location", "");
            descriptionForContactLog.Add("VehicleType", model.EmergencyAssistance.VehicleTypeID.ToString());
            descriptionForContactLog.Add("VehicleYear", model.EmergencyAssistance.VehicleYear);
            descriptionForContactLog.Add("VehicleMake", model.EmergencyAssistance.VehicleMake);
            descriptionForContactLog.Add("VehicleModel", model.EmergencyAssistance.VehicleModel);
            descriptionForContactLog.Add("VehicleColor", model.EmergencyAssistance.VehicleColor);
            descriptionForContactLog.Add("Comments", model.ContactLog.Comments);
            if (model.EmergencyAssistance.Latitude.HasValue)
            {
                descriptionForContactLog.Add("Latitude", model.EmergencyAssistance.Latitude.GetValueOrDefault().ToString());
                descriptionForContactLog.Add("Longitude", model.EmergencyAssistance.Longitude.GetValueOrDefault().ToString());
            }
            model.ContactLog.Description = descriptionForContactLog.GetXml();
            model.EmergencyAssistance.ModifyBy = createdBy;
            model.EmergencyAssistance.ModifyDate = System.DateTime.Now;

            var contactMethod = ReferenceDataRepository.GetContactMethod(ContactMethodNames.PHONE);
            if (contactMethod == null)
            {
                throw new DMSException("Contact Method - Phone is not available in the system.");
            }
            model.ContactLog.ContactMethodID = contactMethod.ID; //For Phone
            var contactCategory = ReferenceDataRepository.GetContactCategory(ContactCategoryNames.EMERGENCY_ASSISTANCE);
            if (contactCategory == null)
            {
                throw new DMSException("Contact Category - Emergency Assistance is not available in the system.");
            }

            model.ContactLog.ContactCategoryID = contactCategory.ID; // For Emergecny Assistance
            model.ContactLog.CreateBy = createdBy;
            model.ContactLog.CreateDate = System.DateTime.Now;
            model.ContactLog.ModifyBy = createdBy;
            model.ContactLog.ModifyDate = System.DateTime.Now;

            //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
            using (TransactionScope tran = new TransactionScope())
            {
                EmergencyAssistanceRepository emergencyAssistanceRepository = new EmergencyAssistanceRepository();

                // Save Emergency Assistance record if one already exists or create otherwise.
                // Create EventLog and ContactLog (related) records
                if (!emergencyAssistanceRepository.IsEmergencyAssistanceRecordExists(model.EmergencyAssistance.InboundCallID))
                {
                    // New Request
                    //model.EmergencyAssistance.CaseID = null;
                    emergencyAssistanceRepository.CreateEmergencyAssistance(model);
                }
                else
                {
                    emergencyAssistanceRepository.SaveEmergencyAssistance(model);
                }

                #region Event Log Old Logic
                // Create an event log and event log link record.
                // If case exists , then link the eventlog to case. Link to InboundCall, otherwise
                //For Event Log
                //EventLogRepository eventLogRepository = new EventLogRepository();

                //IRepository<Event> eventRepository = new EventRepository();
                //Event theEvent = eventRepository.Get<string>(EventNames.EMERGENCY_ASSISTANCE);

                //if (theEvent == null)
                //{
                //    throw new DMSException("Invalid event name");
                //}

                //EventLog eventLog = new EventLog();
                //eventLog.Source = eventSource;
                //eventLog.EventID = theEvent.ID;
                //eventLog.SessionID = sessionID;
                //eventLog.Description = eventDetails.GetXml();
                //eventLog.CreateDate = DateTime.Now;
                //eventLog.CreateBy = createdBy;
                //long eventLogId = 0;
                //if (model.EmergencyAssistance.CaseID != null)
                //{
                //    eventLogId = eventLogRepository.Add(eventLog, model.EmergencyAssistance.CaseID, EntityNames.CASE);
                //}
                //else
                //{
                //    eventLogId = eventLogRepository.Add(eventLog, model.EmergencyAssistance.InboundCallID, EntityNames.INBOUND_CALL);
                //}
                #endregion

                if (model.ContactInsertRequired)
                {
                    // Contact Log related records
                    // Get the ContactTypeID for EmergencyAgency
                    ContactStaticDataRepository staticDataRepository = new ContactStaticDataRepository();
                    ContactType contactType = staticDataRepository.GetTypeByName("EmergencyAgency");
                    if (contactType == null)
                    {
                        throw new DMSException("Contact Type for EmergencyAgency is not set up in the system");
                    }
                    ContactLogRepository contactLogRepository = new ContactLogRepository();

                    model.ContactLog.ContactTypeID = contactType.ID;
                    model.ContactLog.Comments = model.Comment.Description;
                    contactLogRepository.Save(model.ContactLog, createdBy, model.EmergencyAssistance.ID, EntityNames.EMERGENCY_ASSISTANCE);
                    // Create contactLogReason and EventLogLink records.
                    ContactLogReason reason = new ContactLogReason();
                    reason.ContactLogID = model.ContactLog.ID;
                    ContactReason contactReason = staticDataRepository.GetContactReason("Get emergency help", "EmergencyAssistance");
                    if (contactReason == null)
                    {
                        throw new DMSException("ContactReason with name - Get emergency help doesn't exist for category = EmergencyAssistance");
                    }
                    reason.ContactReasonID = contactReason.ID;
                    reason.CreateBy = createdBy;
                    reason.CreateDate = DateTime.Now;

                    ContactLogReasonRepository reasonRepository = new ContactLogReasonRepository();
                    reasonRepository.Save(reason, createdBy);

                    // Event Log Link record.

                    ContactLogActionRepository actionLogRepository = new ContactLogActionRepository();
                    actionLogRepository.Save(new ContactLogAction()
                    {
                        ContactActionID = model.ContactActionID,
                        ContactLogID = model.ContactLog.ID
                    }, createdBy);

                }
                // Save Comments
                CommentFacade commentFacade = new CommentFacade();
                //model.Comment.RecordID = model.EmergencyAssistance.ID;
                //int commentID = commentFacade.Save(model.Comment, createdBy);
                // KB: Populate all relevent details like Entity, relatedrecord and comment.
                if (model.Comment != null && !string.IsNullOrEmpty(model.Comment.Description))
                {
                    commentFacade.Save(null, EntityNames.EMERGENCY_ASSISTANCE, model.EmergencyAssistance.ID, model.Comment.Description, createdBy);
                }
                tran.Complete();


            }
            ContactLogFacade contactLogFacade = new ContactLogFacade();
            List<PreviousCallList> previousCallList = contactLogFacade.GetPreviousCallList(model.EmergencyAssistance.ID, model.ContactLog.ID);
            PreviousCallList list = null;
            if (previousCallList != null && previousCallList.Count > 0)
            {
                list = previousCallList.ElementAt(0);
            }
            return list;
        }

        public CasePhoneLocation WSGetPhoneLocation(int inboundCallId)
        {
            CasePhoneLocation phoneLocation = new CasePhoneLocationFacade().GetByInboundCallId(inboundCallId);
            return phoneLocation;
        }
    }

    /// <summary>
    /// Class with extension methods to return objects of another type.
    /// </summary>
    public static class EmergencyAssistanceCallLogExtensions
    {
        /// <summary>
        /// Get the Contact Log object from emergency assistance call log model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>

        //public static ContactLog ToContactLog(this EmergencyAssistanceCallLogModel model)
        //{
        //    ContactLog log = new ContactLog();
        //    log.ID = model.ContactLogID;
        //    log.Company = model.Company;
        //    log.ContactSourceID = model.Source;
        //    log.Direction = model.Direction;
        //    log.Comments = model.Comments;
        //    log.TalkedTo = model.TalkedTo;
        //    log.PhoneNumber = model.PhoneNumber;
        //    log.ContactSourceID = model.Source;
        //    log.Description = 
        //    return log;
        //}
    }
}
