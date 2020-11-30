using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class CaseRepository
    {
        #region Protected Members
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(CaseRepository));

        #endregion

        /// <summary>
        /// Adds the specified case record.
        /// </summary>
        /// <param name="caseRecord">The case record.</param>
        /// <param name="status">The status.</param>
        /// <returns></returns>
        public int Add(Case caseRecord, string status)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseStatus = dbContext.CaseStatus.Where(x => x.Name == status).FirstOrDefault();
                if (caseStatus != null)
                {
                    caseRecord.CaseStatusID = caseStatus.ID;
                }
                dbContext.Cases.Add(caseRecord);
                dbContext.SaveChanges();
                return caseRecord.ID;
            }
        }

        /// <summary>
        /// Sets the SMS available.
        /// </summary>
        /// <param name="caseID">The case ID.</param>
        /// <param name="isSMSAvailable">if set to <c>true</c> [is SMS available].</param>
        public void SetSMSAvailable(int caseID, bool isSMSAvailable)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseRecord = dbContext.Cases.Where(a => a.ID == caseID).FirstOrDefault();
                if (caseRecord != null)
                {
                    caseRecord.IsSMSAvailable = isSMSAvailable;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Updates the vehicle information.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="modifyBy">The modify by.</param>
        public void UpdateVehicleInformation(int caseId, int programId, Vehicle vehicle, string modifyBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseRecord = dbContext.Cases.Where(x => x.ID == caseId).FirstOrDefault();
                if (caseRecord != null)
                {
                    if (vehicle.ID != 0)
                    {
                        caseRecord.VehicleID = vehicle.ID;
                    }
                    else
                    {
                        caseRecord.VehicleID = null;
                    }
                    caseRecord.VehicleVIN = vehicle.VIN;
                    caseRecord.VehicleYear = vehicle.Year;
                    caseRecord.VehicleMake = vehicle.Make;
                    caseRecord.VehicleMakeOther = vehicle.MakeOther;
                    caseRecord.VehicleModel = vehicle.Model;
                    caseRecord.VehicleModelOther = vehicle.ModelOther;
                    caseRecord.VehicleLicenseNumber = vehicle.LicenseNumber;
                    caseRecord.VehicleLicenseState = vehicle.LicenseState;
                    caseRecord.VehicleLicenseCountryID = vehicle.VehicleLicenseCountryID;
                    caseRecord.VehicleDescription = vehicle.Description;
                    caseRecord.VehicleColor = vehicle.Color;
                    caseRecord.VehicleLength = vehicle.Length;
                    caseRecord.VehicleHeight = vehicle.Height;
                    caseRecord.VehicleSource = vehicle.Source;
                    caseRecord.VehicleCategoryID = vehicle.VehicleCategoryID;
                    caseRecord.VehicleTypeID = vehicle.VehicleTypeID;
                    caseRecord.VehicleRVTypeID = vehicle.RVTypeID;
                    caseRecord.TrailerTypeID = vehicle.TrailerTypeID;
                    caseRecord.TrailerTypeOther = vehicle.TrailerTypeOther;
                    caseRecord.TrailerSerialNumber = vehicle.SerialNumber;
                    caseRecord.TrailerNumberofAxles = vehicle.NumberofAxles;
                    caseRecord.TrailerHitchTypeID = vehicle.HitchTypeID;
                    caseRecord.TrailerHitchTypeOther = vehicle.HitchTypeOther;
                    caseRecord.TrailerBallSize = vehicle.TrailerBallSize;
                    caseRecord.TrailerBallSizeOther = vehicle.TrailerBallSizeOther;
                    caseRecord.VehicleTireSize = vehicle.TireSize;
                    caseRecord.VehicleTireBrand = vehicle.TireBrand;
                    caseRecord.VehicleTireBrandOther = vehicle.TireBrandOther;
                    caseRecord.VehicleTransmission = vehicle.Transmission;
                    caseRecord.VehicleEngine = vehicle.Engine;
                    caseRecord.VehicleGVWR = vehicle.GVWR;
                    caseRecord.VehicleChassis = vehicle.Chassis;
                    caseRecord.VehiclePurchaseDate = vehicle.PurchaseDate;
                    caseRecord.VehicleWarrantyStartDate = vehicle.WarrantyStartDate;
                    caseRecord.VehicleWarrantyEndDate = vehicle.WarrantyEndDate;
                    caseRecord.VehicleStartMileage = vehicle.StartMileage;
                    caseRecord.VehicleEndMileage = vehicle.EndMileage;


                    caseRecord.VehicleMileageUOM = vehicle.MileageUOM;
                    caseRecord.VehicleIsFirstOwner = vehicle.IsFirstOwner;
                    caseRecord.VehicleIsSportUtilityRV = vehicle.IsSportUtilityRV;
                    caseRecord.VehicleSource = vehicle.Source;
                    //TFS: 502. caseRecord.ProgramID = programId;
                    caseRecord.ModifyBy = modifyBy;
                    caseRecord.ModifyDate = DateTime.Now;


                    //TFS:212 Warranty details                    
                    caseRecord.VehicleWarrantyMileage = vehicle.WarrantyMileage;
                    caseRecord.VehicleWarrantyPeriod = vehicle.WarrantyPeriod;
                    caseRecord.VehicleWarrantyPeriodUOM = vehicle.WarrantyPeriodUOM;

                    // Calculating Case.IsEligible as: True when GETDATE between startdate and enddate and currentmileage < endmileage; False otherwise.
                    var progInfo = dbContext.GetProgramConfigurationForProgram(programId, "Vehicle", "Validation").ToList<ProgramInformation_Result>();
                    bool calculateIsVehicleEligible = progInfo.Where(x => (x.Name.Equals("WarrantyApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).Count() > 0;

                    if (calculateIsVehicleEligible)
                    {
                        DateTime now = DateTime.Now;

                        if (vehicle.WarrantyStartDate == null || vehicle.WarrantyEndDate == null || vehicle.CurrentMileage == null || vehicle.EndMileage == null)
                        {
                            caseRecord.IsVehicleEligible = null;
                        }
                        if (now >= vehicle.WarrantyStartDate && now <= vehicle.WarrantyEndDate && vehicle.CurrentMileage <= vehicle.EndMileage)
                        {
                            caseRecord.IsVehicleEligible = true;
                        }
                        else
                        {
                            caseRecord.IsVehicleEligible = false;
                        }
                        caseRecord.VehicleCurrentMileage = vehicle.CurrentMileage;
                    }
                    if (vehicle != null && vehicle.VehicleTypeID != null && !calculateIsVehicleEligible)
                    {
                        VehicleType vt = null;
                        vt = dbContext.VehicleTypes.Where(a => a.ID == vehicle.VehicleTypeID).FirstOrDefault();
                        if (vt != null && vt.Name == "RV")
                        {
                            caseRecord.VehicleCurrentMileage = vehicle.CurrentMileage;
                        }
                    }
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the vehicle information.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public Vehicle GetVehicleInformation(int caseId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vehicle vehicle = new Vehicle();
                var caseRecord = dbContext.Cases.Where(x => x.ID == caseId).FirstOrDefault();
                if (caseRecord != null)
                {

                    if (caseRecord.VehicleID.HasValue)
                    {
                        vehicle.ID = caseRecord.VehicleID.Value;
                    }
                    vehicle.VIN = caseRecord.VehicleVIN;
                    vehicle.Year = caseRecord.VehicleYear;
                    vehicle.Make = caseRecord.VehicleMake;
                    vehicle.MakeOther = caseRecord.VehicleMakeOther;
                    vehicle.Model = caseRecord.VehicleModel;
                    vehicle.ModelOther = caseRecord.VehicleModelOther;
                    vehicle.LicenseNumber = caseRecord.VehicleLicenseNumber;
                    vehicle.LicenseState = caseRecord.VehicleLicenseState;
                    vehicle.VehicleLicenseCountryID = caseRecord.VehicleLicenseCountryID;
                    vehicle.Description = caseRecord.VehicleDescription;
                    vehicle.Color = caseRecord.VehicleColor;
                    vehicle.Length = caseRecord.VehicleLength;
                    vehicle.Height = caseRecord.VehicleHeight;
                    vehicle.Source = caseRecord.VehicleSource;
                    vehicle.VehicleCategoryID = caseRecord.VehicleCategoryID;
                    vehicle.VehicleTypeID = caseRecord.VehicleTypeID;
                    vehicle.RVTypeID = caseRecord.VehicleRVTypeID;
                    vehicle.TrailerTypeID = caseRecord.TrailerTypeID;
                    vehicle.TrailerTypeOther = caseRecord.TrailerTypeOther;
                    vehicle.SerialNumber = caseRecord.TrailerSerialNumber;
                    vehicle.NumberofAxles = caseRecord.TrailerNumberofAxles;
                    vehicle.HitchTypeID = caseRecord.TrailerHitchTypeID;
                    vehicle.HitchTypeOther = caseRecord.TrailerHitchTypeOther;
                    vehicle.TrailerBallSize = caseRecord.TrailerBallSize;
                    vehicle.TrailerBallSizeOther = caseRecord.TrailerBallSizeOther;
                    vehicle.TireSize = caseRecord.VehicleTireSize;
                    vehicle.TireBrand = caseRecord.VehicleTireBrand;
                    vehicle.TireBrandOther = caseRecord.VehicleTireBrandOther;
                    vehicle.Transmission = caseRecord.VehicleTransmission;
                    vehicle.Engine = caseRecord.VehicleEngine;
                    vehicle.GVWR = caseRecord.VehicleGVWR;
                    vehicle.Chassis = caseRecord.VehicleChassis;
                    vehicle.PurchaseDate = caseRecord.VehiclePurchaseDate;
                    vehicle.WarrantyStartDate = caseRecord.VehicleWarrantyStartDate;
                    vehicle.StartMileage = caseRecord.VehicleStartMileage;
                    vehicle.EndMileage = caseRecord.VehicleEndMileage;
                    vehicle.CurrentMileage = caseRecord.VehicleCurrentMileage;
                    vehicle.Source = caseRecord.VehicleSource;
                    vehicle.MileageUOM = caseRecord.VehicleMileageUOM;
                    vehicle.IsFirstOwner = caseRecord.VehicleIsFirstOwner;
                    vehicle.IsSportUtilityRV = caseRecord.VehicleIsSportUtilityRV;
                    vehicle.ModifyBy = caseRecord.ModifyBy;
                    vehicle.ModifyDate = caseRecord.ModifyDate;
                    vehicle.MembershipID = caseRecord.MemberID;
                    vehicle.MemberID = caseRecord.MemberID;

                    //TFS:212 Warranty new fields.
                    vehicle.WarrantyMileage = caseRecord.VehicleWarrantyMileage;
                    vehicle.WarrantyPeriod = caseRecord.VehicleWarrantyPeriod;
                    vehicle.WarrantyPeriodUOM = caseRecord.VehicleWarrantyPeriodUOM;
                    vehicle.WarrantyEndDate = caseRecord.VehicleWarrantyEndDate;

                    return vehicle;
                }
                return vehicle;
            }
        }

        /// <summary>
        /// Updates the contact details.
        /// </summary>
        /// <param name="c">The c.</param>
        public void UpdateContactDetails(Case c)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseRecord = dbContext.Cases.Where(e => e.ID == c.ID).FirstOrDefault();

                if (caseRecord != null)
                {
                    #region Program Configuration
                    //Retrieve Program Configuration to check Email Should be updated or Not.
                    //When Configuration is available and value is set to yes do not update email address
                    logger.InfoFormat("Trying to Update Member Contact Details. Checking ShowSurveyEmail is configured or not for Program ID {0}", caseRecord.ProgramID);
                    ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                    var programConfigurationList = programMaintenanceRepository.GetProgramInfo(caseRecord.ProgramID, "Application", "Rule");
                    var isShowSurveyEmail = programConfigurationList.Where(x => (x.Name.Equals("ShowSurveyEmail", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault() != null;
                    if (isShowSurveyEmail)
                    {
                        logger.InfoFormat("ShowSurveyEmail is configured for Program ID {0} So Case ID {1} Contact Email will not be updated", caseRecord.ProgramID, caseRecord.ID);
                    }
                    else
                    {
                        logger.InfoFormat("ShowSurveyEmail is not configured for Program ID {0} So Case ID {1} Contact Email will be updated", caseRecord.ProgramID, caseRecord.ID);
                    }
                    #endregion

                    caseRecord.ContactPhoneTypeID = c.ContactPhoneTypeID;
                    caseRecord.ContactAltPhoneTypeID = c.ContactAltPhoneTypeID;

                    caseRecord.ContactPhoneNumber = c.ContactPhoneNumber;
                    caseRecord.ContactAltPhoneNumber = c.ContactAltPhoneNumber;

                    caseRecord.ContactFirstName = c.ContactFirstName;
                    caseRecord.ContactLastName = c.ContactLastName;

                    // CR: 1239 - DeliveryDriver
                    caseRecord.IsDeliveryDriver = c.IsDeliveryDriver;

                    //TFS : 357
                    if (!isShowSurveyEmail)
                    {
                        caseRecord.ContactEmail = c.ContactEmail;
                    }

                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the case by id.
        /// </summary>
        /// <param name="caseid">The caseid.</param>
        /// <returns></returns>
        public Case GetCaseById(int caseid)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.Cases.Include("Program").Include(c => c.SourceSystem).Where(id => id.ID == caseid).FirstOrDefault();
            }
        }

        /// <summary>
        /// Updates the program ID.
        /// </summary>
        /// <param name="model">The model.</param>
        //public void UpdateProgramID(Case model)
        //{
        //    using (DMSEntities entities = new DMSEntities())
        //    {
        //        Case caseDetails = entities.Cases.Where(id => id.ID == model.ID).FirstOrDefault();
        //        if (caseDetails != null)
        //        {
        //            caseDetails.ProgramID = model.ProgramID;
        //            entities.SaveChanges();
        //        }
        //    }
        //}

        //Lakshmi - Email on Map tab

        /// <summary>
        /// Updates the contact details.
        /// </summary>
        /// <param name="c">The c.</param>
        public void UpdateContactEmailAddress(string email, int? reasonId, int caseID, string username)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseRecord = dbContext.Cases.Where(e => e.ID == caseID).FirstOrDefault();
                if (caseRecord != null)
                {
                    caseRecord.ContactEmail = email;
                    caseRecord.ReasonID = (reasonId != null) ? reasonId : null;
                    caseRecord.ModifyBy = username;
                    caseRecord.ModifyDate = DateTime.Now;

                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the Declined reason by id.
        /// </summary>
        /// <param name="caseid">The caseid.</param>
        /// <returns></returns>
        public ContactEmailDeclineReason DeclinedReasonById(int declinedreasonid)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ContactEmailDeclineReasons.Where(id => id.ID == declinedreasonid).FirstOrDefault();
            }
        }


        /// <summary>
        /// Sets the vehicle current mileage.
        /// </summary>
        /// <param name="caseId">The case unique identifier.</param>
        /// <param name="mileage">The mileage.</param>
        public void SetVehicleCurrentMileage(int caseId, int mileage)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var c = dbContext.Cases.Where(x => x.ID == caseId).FirstOrDefault();
                if (c != null)
                {
                    c.VehicleCurrentMileage = mileage;
                }

                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="caseId"></param>
        /// <param name="claimNumber"></param>
        public void SetClaimReferenceNumber(int caseId, string claimNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var c = dbContext.Cases.Where(x => x.ID == caseId).FirstOrDefault();
                if (c != null)
                {
                    c.ReferenceNumber = claimNumber;
                }

                dbContext.SaveChanges();
            }
        }

        //Lakshmi - Orphaned Service Request Enhancement

        public void UpdateMemberNoInCase(int servicerequestID, int memberid, string memberno, string username)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var svcReqDetail = dbContext.ServiceRequests.Where(e => e.ID == servicerequestID).FirstOrDefault();
                int caseid = svcReqDetail.CaseID;
                if (svcReqDetail != null)
                {
                    var caseRecord = dbContext.Cases.Where(e => e.ID == caseid).FirstOrDefault();
                    if (caseRecord != null)
                    {
                        caseRecord.MemberID = memberid;
                        caseRecord.MemberNumber = memberno;
                        caseRecord.ModifyBy = username;
                        caseRecord.ModifyDate = DateTime.Now;

                        dbContext.SaveChanges();
                    }
                }
            }
        }

        public void UpdateMemberStatus(Case caseRecord, string currentUser)
        {

            Case c = GetCaseById(caseRecord.ID);
            if (c == null)
            {
                throw new DMSException("Case not found with ID : " + caseRecord.ID);

            }
            using (DMSEntities dbContext = new DMSEntities())
            {

                c.MemberStatus = caseRecord.MemberStatus;
                c.ModifyBy = currentUser;
                c.ModifyDate = DateTime.Now;

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the program identifier for Case Record.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="caseID">The case identifier.</param>
        /// <param name="currentUser">The current user.</param>
        /// <exception cref="DMSException">Case Not Found with ID :  + caseID</exception>
        public void UpdateProgramID(int programID, int caseID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Case existingCase = dbContext.Cases.Where(a => a.ID == caseID).FirstOrDefault();
                if (existingCase == null)
                {
                    throw new DMSException("Case Not Found with ID : " + caseID);
                }
                existingCase.ProgramID = programID;
                existingCase.ModifyBy = currentUser;
                existingCase.ModifyDate = DateTime.Now;

                dbContext.Entry(existingCase).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        public ServiceRequestApiModel AddCaseFromWebRequest(ServiceRequestApiModel model)
        {
            MemberRepository memRepo = new MemberRepository();
            MembershipRepository membershipRepo = new MembershipRepository();
            VehicleRepository vehicleRepo = new VehicleRepository();
            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();

            Member member = memRepo.Get(model.InternalMemberID.GetValueOrDefault());
            Membership membership = membershipRepo.Get(model.InternalCustomerGroupID.GetValueOrDefault());
            //TFS #1311 : Set Call Type as New Call --> CallType callType = ReferenceDataRepository.GetCallTypeByName(CallTypeNames.WEB_SERVICE);
            CallType callType = ReferenceDataRepository.GetCallTypeByName(CallTypeNames.NEW_CALL);
            SourceSystem sourceSystem = ReferenceDataRepository.GetSourceSystemByName(SourceSystemName.WEB_SERVICE);
            int? sourceSystemID = sourceSystem.ID;
            if (!string.IsNullOrWhiteSpace(model.SourceSystem))
            {
                sourceSystem = ReferenceDataRepository.GetSourceSystemByName(model.SourceSystem);
                if(sourceSystem != null)
                {
                    sourceSystemID = sourceSystem.ID;
                }
            }
            Vehicle vehicle = vehicleRepo.GetVehicle(model.VehicleID.GetValueOrDefault());
            
            int? nullValue = null;
            Language language = ReferenceDataRepository.GetLanguageByName("English");
            
            int? licenseCountryCode = null;
            if (!string.IsNullOrWhiteSpace(model.LicenseCountry))
            {
                var countryByCode = lookUpRepo.GetCountryByCode(model.LicenseCountry);
                if (countryByCode != null)
                {
                    licenseCountryCode = countryByCode.ID;
                }
            }
            //Handle the case where the vehicle was not added to vehicle table. We need to store the input values on Case.
            Case caseRecord = new Case()
            {
                MemberID = model.InternalMemberID,
                ProgramID = model.ProgramID,
                VehicleID = model.VehicleID,
                ReferenceNumber = model.ReferenceNumber.NullIfBlank(),
                //TFS #1311 -->MemberNumber = membership != null ? membership.MembershipNumber : string.Empty,
                MemberNumber = member.MemberNumber.NullIfBlank(),
                MemberStatus = member.EffectiveDate.GetValueOrDefault() <= DateTime.Today && member.ExpirationDate.GetValueOrDefault() >= DateTime.Today? "Active" : "Inactive",
                CallTypeID = callType != null ? callType.ID : nullValue,
                //TFS #1311 --> Language = model.Language,
                Language = language != null ? language.ID.ToString() : null,
                VehicleVIN = vehicle != null ? vehicle.VIN.NullIfBlank() : model.VehicleVIN.NullIfBlank(),
                VehicleTypeID = vehicle != null ? vehicle.VehicleTypeID : model.VehicleTypeID,
                VehicleMake = vehicle != null ? vehicle.Make.NullIfBlank() : model.VehicleMake.NullIfBlank(),
                VehicleMakeOther = vehicle != null ? vehicle.MakeOther.NullIfBlank() : model.VehicleMakeOther.NullIfBlank(),
                VehicleModel = vehicle != null ? vehicle.Model.NullIfBlank() : model.VehicleModel.NullIfBlank(),
                VehicleModelOther = vehicle != null ? vehicle.ModelOther.NullIfBlank() : model.VehicleModelOther.NullIfBlank(),
                VehicleYear = vehicle != null ? vehicle.Year : model.VehicleYear.ToString(),
                VehicleSource = vehicle != null ? "Vehicle" : "ServiceRequest",
                VehicleCategoryID = vehicle != null ? vehicle.VehicleCategoryID : model.VehicleCategoryID,
                VehicleRVTypeID = model.RVTypeID,
                // Set other vehicle attributes
                VehicleChassis = vehicle != null ? vehicle.Chassis.NullIfBlank() : model.VehicleChassis.NullIfBlank(),
                VehicleColor = vehicle != null ? vehicle.Color.NullIfBlank() : model.VehicleColor.NullIfBlank(),
                VehicleCurrentMileage = vehicle != null ? vehicle.CurrentMileage : null,
                VehicleEndMileage = vehicle != null ? vehicle.EndMileage : null,
                VehicleEngine = vehicle != null ? vehicle.Engine : model.VehicleEngine,
                VehicleLicenseCountryID = vehicle != null ? vehicle.VehicleLicenseCountryID : licenseCountryCode,
                VehicleLicenseState = vehicle != null ? vehicle.LicenseState.NullIfBlank() : model.LicenseState.NullIfBlank(),
                VehicleLicenseNumber = vehicle != null ? vehicle.LicenseNumber.NullIfBlank() : model.LicenseNumber.NullIfBlank(),
                VehicleStartMileage = vehicle != null ? vehicle.StartMileage : null,

                VehicleWarrantyEndDate = vehicle != null ? vehicle.WarrantyEndDate : null,
                VehicleWarrantyMileage = vehicle != null ? vehicle.WarrantyMileage : null,
                VehicleWarrantyPeriod = vehicle != null ? vehicle.WarrantyPeriod : null,
                VehicleWarrantyPeriodUOM = vehicle != null ? vehicle.WarrantyPeriodUOM : null,
                VehicleWarrantyStartDate = vehicle != null ? vehicle.WarrantyStartDate : null,

                SourceSystemID = sourceSystemID,
                ContactFirstName = model.ContactFirstName.NullIfBlank(),
                ContactLastName = model.ContactLastName.NullIfBlank(),
                ContactPhoneNumber = model.ContactPhoneNumber.NullIfBlank(),
                ContactPhoneTypeID = model.ContactPhoneTypeID,
                ContactAltPhoneNumber = model.ContactAltPhoneNumber.NullIfBlank(),
                ContactAltPhoneTypeID = model.AltContactPhoneTypeID,
                IsSMSAvailable = model.IsSMSAvailable,
                //TFS #1371
                ContactEmail = model.ContactEmail.NullIfBlank(),
                //TFS #1311IsSafe = model.IsEmergency,
                IsSafe = true,
                CreateDate = DateTime.Now,
                CreateBy = model.CurrentUser
                //TFS #1311                                
            };
            Add(caseRecord, "Open");
            model.CaseID = caseRecord.ID;
            model.VehicleCategoryID = vehicle != null ? vehicle.VehicleCategoryID : nullValue;
            return model;
        }
    }
}
