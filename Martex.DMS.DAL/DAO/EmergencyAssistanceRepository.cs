using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Extensions;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;
namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class EmergencyAssistanceRepository
    {
        /// <summary>
        /// Gets the emergency assistance.
        /// </summary>
        /// <param name="InboundCallID">The inbound call ID.</param>
        /// <returns></returns>
        public EmergencyAssistance GetEmergencyAssistance(int InboundCallID)
        {
            using (DMSEntities entity = new DMSEntities())
            {
                EmergencyAssistance eAssistance = new EmergencyAssistance();
               
                EmergencyAssistance existingEmergecyAssistance = entity.EmergencyAssistances.Where(u => u.InboundCallID == InboundCallID).FirstOrDefault();
                if (existingEmergecyAssistance != null)
                {
                    eAssistance.MemberFirstName = existingEmergecyAssistance.MemberFirstName;
                    eAssistance.MemberLastName = existingEmergecyAssistance.MemberLastName;
                    eAssistance.ContactPhoneNumber = existingEmergecyAssistance.ContactPhoneNumber;
                    eAssistance.ANIPhoneNumber = existingEmergecyAssistance.ANIPhoneNumber;

                    eAssistance.VehicleTypeID = existingEmergecyAssistance.VehicleTypeID;
                    eAssistance.VehicleYear = existingEmergecyAssistance.VehicleYear;
                    eAssistance.VehicleMake = existingEmergecyAssistance.VehicleMake;
                    eAssistance.VehicleMakeOther = existingEmergecyAssistance.VehicleMakeOther;
                    eAssistance.VehicleModel = existingEmergecyAssistance.VehicleModel;
                    eAssistance.VehicleModelOther = existingEmergecyAssistance.VehicleModelOther;
                    eAssistance.VehicleColor = existingEmergecyAssistance.VehicleColor;
                    eAssistance.Latitude = existingEmergecyAssistance.Latitude;
                    eAssistance.Longitude = existingEmergecyAssistance.Longitude;
                    eAssistance.Address = existingEmergecyAssistance.Address;
                    eAssistance.ID = existingEmergecyAssistance.ID;

                    eAssistance.EmergencyAssistanceReasonID = existingEmergecyAssistance.EmergencyAssistanceReasonID;
                    eAssistance.InboundCallID = existingEmergecyAssistance.InboundCallID;
                    eAssistance.VehicleLicenseNumber = existingEmergecyAssistance.VehicleLicenseNumber;
                    eAssistance.VehicleLicenseState = existingEmergecyAssistance.VehicleLicenseState;
                    eAssistance.VehicleLicenseStateCountryID = existingEmergecyAssistance.VehicleLicenseStateCountryID;
                }
                return eAssistance;
            }
        }
        /// <summary>
        /// Determines whether [is emergency assistance record exists] [the specified in bound call ID].
        /// </summary>
        /// <param name="inBoundCallID">The in bound call ID.</param>
        /// <returns>
        ///   <c>true</c> if [is emergency assistance record exists] [the specified in bound call ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsEmergencyAssistanceRecordExists(int? inBoundCallID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var count = dbContext.EmergencyAssistances.Where(id => id.InboundCallID == inBoundCallID).Count();
                return count > 0;
            }
        }
        /// <summary>
        /// Saves the emergency assistance.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="DMSException">Inbound call details not found.</exception>
        public void SaveEmergencyAssistance(EmergencyAssistanceModel model)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                //For Emergency Assistance
                EmergencyAssistance existingDetails = entities.EmergencyAssistances.Where(id => id.InboundCallID == model.EmergencyAssistance.InboundCallID).FirstOrDefault();
                if (existingDetails == null)
                {
                    throw new DMSException("Inbound call details not found.");
                }
                existingDetails.ModifyBy = model.EmergencyAssistance.ModifyBy;
                existingDetails.ModifyDate = DateTime.Now;
                existingDetails.VehicleTypeID = model.EmergencyAssistance.VehicleTypeID;
                existingDetails.VehicleYear = model.EmergencyAssistance.VehicleYear;
                existingDetails.VehicleMake = model.EmergencyAssistance.VehicleMake;
                existingDetails.VehicleMakeOther = model.EmergencyAssistance.VehicleMakeOther;
                existingDetails.VehicleModel = model.EmergencyAssistance.VehicleModel;
                existingDetails.VehicleModelOther = model.EmergencyAssistance.VehicleModelOther;
                existingDetails.VehicleColor = model.EmergencyAssistance.VehicleColor;
                existingDetails.Latitude = model.EmergencyAssistance.Latitude;
                existingDetails.Longitude = model.EmergencyAssistance.Longitude;
                existingDetails.MemberFirstName = model.EmergencyAssistance.MemberFirstName;
                existingDetails.MemberLastName = model.EmergencyAssistance.MemberLastName;
                existingDetails.Address = model.EmergencyAssistance.Address;

                existingDetails.ContactPhoneNumber = model.CallBackNumber;
                if (model.EmergencyAssistance.ContactPhoneTypeID > 0)
                {
                    existingDetails.ContactPhoneTypeID = model.EmergencyAssistance.ContactPhoneTypeID;
                }
                existingDetails.CrossStreet1 = model.CasePhoneLocation.IntersectionStreet1;
                existingDetails.CrossStreet2 = model.CasePhoneLocation.IntersectionStreet2;

                existingDetails.StateProvince = model.CasePhoneLocation.CivicState;
                existingDetails.PostalCode = model.CasePhoneLocation.CivicZip;
                existingDetails.Country = model.CasePhoneLocation.CivicCountry;
                existingDetails.EmergencyAssistanceReasonID = model.EmergencyAssistance.EmergencyAssistanceReasonID;
                existingDetails.VehicleLicenseNumber = model.EmergencyAssistance.VehicleLicenseNumber;
                existingDetails.VehicleLicenseState = model.EmergencyAssistance.VehicleLicenseState;
                existingDetails.VehicleLicenseStateCountryID = model.EmergencyAssistance.VehicleLicenseStateCountryID;
                if (model.EmergencyAssistance.CaseID != 0)
                {
                    existingDetails.CaseID = model.EmergencyAssistance.CaseID;
                }

                entities.SaveChanges();

                model.EmergencyAssistance.ID = existingDetails.ID;
            }
            
        }
        /// <summary>
        /// Updates the case details.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="caseId">The case id.</param>
        /// <param name="modifyBy">The modify by.</param>
        public void UpdateCaseDetails(int inboundCallId, int caseId, string modifyBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var emergencyRecord = dbContext.EmergencyAssistances.Where(x => x.InboundCallID == inboundCallId).FirstOrDefault();
                var caseDetails = dbContext.Cases.Where(u => u.ID == caseId).FirstOrDefault();
                
                if (emergencyRecord != null)
                {
                    emergencyRecord.CaseID = caseId;
                    emergencyRecord.ModifyBy = modifyBy;
                    emergencyRecord.ModifyDate = DateTime.Now;
                    if (caseDetails != null)
                    {
                        // Update Vehicle Details into Case Table.
                        caseDetails.VehicleTypeID = emergencyRecord.VehicleTypeID;
                        caseDetails.VehicleYear = emergencyRecord.VehicleYear;
                        caseDetails.VehicleMake = emergencyRecord.VehicleMake;
                        caseDetails.VehicleMakeOther = emergencyRecord.VehicleMakeOther;

                        caseDetails.VehicleModel = emergencyRecord.VehicleModel;
                        caseDetails.VehicleModelOther = emergencyRecord.VehicleModelOther;

                        caseDetails.VehicleColor = emergencyRecord.VehicleColor;
                        caseDetails.VehicleLicenseNumber = emergencyRecord.VehicleLicenseNumber;
                        caseDetails.VehicleLicenseState = emergencyRecord.VehicleLicenseState;
                        caseDetails.VehicleLicenseCountryID = emergencyRecord.VehicleLicenseStateCountryID;
                    }
                    dbContext.SaveChanges();
                }
                // Pull the existing case and retrieve the vehicle details and set them on emergency record.
            }
        }
        /// <summary>
        /// Creates the emergency assistance.
        /// </summary>
        /// <param name="model">The model.</param>
        public void CreateEmergencyAssistance(EmergencyAssistanceModel model)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                //For Emergency Assistance

                EmergencyAssistance existingDetails = entities.EmergencyAssistances.Where(id => id.InboundCallID == model.EmergencyAssistance.InboundCallID).FirstOrDefault();
                if (existingDetails == null)
                {
                    if (model.EmergencyAssistance.ContactPhoneTypeID == 0)
                    {
                        model.EmergencyAssistance.ContactPhoneTypeID = null;
                    }
                    if (model.EmergencyAssistance.CaseID != null && model.EmergencyAssistance.CaseID > 0)
                    {
                        model.EmergencyAssistance.CaseID = model.EmergencyAssistance.CaseID;
                    }
                    else
                    {
                        model.EmergencyAssistance.CaseID = null;
                    }
                    model.EmergencyAssistance.Address = model.EmergencyAssistance.Address;

                    model.EmergencyAssistance.ContactPhoneNumber = model.CallBackNumber;
                    model.EmergencyAssistance.CrossStreet1 = model.CasePhoneLocation.IntersectionStreet1;
                    model.EmergencyAssistance.CrossStreet2 = model.CasePhoneLocation.IntersectionStreet2;

                    model.EmergencyAssistance.StateProvince = model.CasePhoneLocation.CivicState;
                    model.EmergencyAssistance.PostalCode = model.CasePhoneLocation.CivicZip;
                    model.EmergencyAssistance.Country = model.CasePhoneLocation.CivicCountry;

                    model.EmergencyAssistance.CreateBy = model.EmergencyAssistance.ModifyBy;
                    model.EmergencyAssistance.CreateDate = DateTime.Now;
                    entities.EmergencyAssistances.Add(model.EmergencyAssistance);
                    
                    entities.SaveChanges();
                    existingDetails = model.EmergencyAssistance;
                }
            }
            
        }

        /// <summary>
        /// Determines whether the specified ea reason id is accident.
        /// </summary>
        /// <param name="eaReasonId">The ea reason id.</param>
        /// <returns>
        ///   <c>true</c> if the specified ea reason id is accident; otherwise, <c>false</c>.
        /// </returns>
        public bool IsAccident(int eaReasonId)
        {
           bool returnValue=false;
          using (DMSEntities entities = new DMSEntities())
          {
             int count= entities.EmergencyAssistanceReasons.Where(er=>er.ID==eaReasonId && er.Name=="Accident").Count();
              if(count >0)
              {
                returnValue=true;
              }
          } 
            return returnValue;
        }
    }
}
