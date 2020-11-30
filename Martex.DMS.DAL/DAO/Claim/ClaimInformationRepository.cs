using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Gets the claim.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public Claim GetClaim(int claimID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Claim claim = dbContext.Claims.Include("PurchaseOrder").Where(u => u.ID == claimID && u.IsActive == true).FirstOrDefault();
                if (claim == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Claim Details for the ID {0}", claimID));
                }
                return claim;
            }
        }

        private string LeftPadZeroes(string s, int maxLengthOfString)
        {
            if (string.IsNullOrEmpty(s))
            {
                s = string.Empty;
            }
            int numberOfZerosToPad = (maxLengthOfString - s.Length);
            string zeros = string.Empty;
            for (int i = 0, l = numberOfZerosToPad; i < l; i++)
            {
                zeros += "0";
            }

            return zeros + s;
        }

        /// <summary>
        /// Updates the member claim reference number.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException"></exception>
        public void UpdateMemberClaimReferenceNumber(int memberID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Member memeber = dbContext.Members.Where(u => u.ID == memberID).FirstOrDefault();
                if (string.IsNullOrEmpty(memeber.ClaimSubmissionNumber))
                {
                    NextNumber nextNumber = dbContext.NextNumbers.Where(u => u.Name.Equals("ClaimSubmissionNumber")).FirstOrDefault();
                    if (nextNumber == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve Configuration for {0}", "ClaimSubmissionNumber"));
                    }
                    nextNumber.Value = nextNumber.Value.GetValueOrDefault() + 1;

                    // Pad zeros to make it 6 digits

                    string number = "M" + LeftPadZeroes((nextNumber.Value.GetValueOrDefault()).ToString(), 6);

                    memeber.ClaimSubmissionNumber = number;
                    memeber.ModifyBy = null;
                    memeber.ModifyDate = null;
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Saves the claim information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void SaveClaimInformation(Claim model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingrecord = dbContext.Claims.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingrecord == null)
                {
                    model.IsActive = true;
                    model.CreateBy = userName;
                    model.CreateDate = DateTime.Now;
                    model.ClaimDecisionDate = null;
                    model.ClaimDecisionBy = null;
                    model.ModifyBy = null;
                    model.ModifyDate = null;
                    model.ExportDate = null;
                    model.ExportBatchID = null;
                    model.CheckNumber = null;
                    model.CheckClearedDate = null;
                    model.ClientPaymentID = null;
                    model.PaymentTypeID = null;
                    model.PaymentDate = null;
                    dbContext.Claims.Add(model);
                }
                else
                {
                    existingrecord.ModifyBy = userName;
                    existingrecord.ModifyDate = DateTime.Now;

                    existingrecord.ClaimDate = model.ClaimDate;
                    existingrecord.ReceivedDate = model.ReceivedDate;
                    existingrecord.ReceiveContactMethodID = model.ReceiveContactMethodID;


                    existingrecord.ContactName = model.ContactName;
                    existingrecord.ContactPhoneNumber = model.ContactPhoneNumber;

                    existingrecord.ContactEmailAddress = model.ContactEmailAddress;

                    existingrecord.PaymentAddressLine1 = model.PaymentAddressLine1;
                    existingrecord.PaymentAddressLine2 = model.PaymentAddressLine2;
                    existingrecord.PaymentAddressLine3 = model.PaymentAddressLine3;

                    existingrecord.PaymentAddressCity = model.PaymentAddressCity;
                    existingrecord.PaymentAddressCountryID = model.PaymentAddressCountryID;
                    existingrecord.PaymentAddressCountryCode = model.PaymentAddressCountryCode;
                    existingrecord.PaymentAddressStateProvinceID = model.PaymentAddressStateProvinceID;
                    existingrecord.PaymentAddressStateProvince = model.PaymentAddressStateProvince;
                    existingrecord.PaymentAddressPostalCode = model.PaymentAddressPostalCode;

                    existingrecord.AmountRequested = model.AmountRequested;
                    existingrecord.AmountApproved = model.AmountApproved;

                    existingrecord.ClaimRejectReasonID = model.ClaimRejectReasonID;
                    existingrecord.ClaimRejectReasonOther = model.ClaimRejectReasonOther;

                    #region Service Section
                    existingrecord.ServiceProductCategoryID = model.ServiceProductCategoryID;
                    existingrecord.ServiceLocation = model.ServiceLocation;
                    existingrecord.DestinationLocation = model.DestinationLocation;
                    existingrecord.ServiceFacilityName = model.ServiceFacilityName;
                    existingrecord.ServiceFacilityPACode = model.ServiceFacilityPACode;
                    existingrecord.ServiceMiles = model.ServiceMiles;
                    existingrecord.IsServiceReceiptOnFile = model.IsServiceReceiptOnFile;
                    #endregion

                    #region Vehcile Section
                    existingrecord.VehicleTypeID = model.VehicleTypeID;
                    existingrecord.VehicleCategoryID = model.VehicleCategoryID;
                    existingrecord.RVTypeID = model.RVTypeID;
                    existingrecord.VehicleVIN = model.VehicleVIN;
                    existingrecord.VehicleYear = model.VehicleYear;
                    existingrecord.VehicleMake = model.VehicleMake;
                    existingrecord.VehicleMakeOther = model.VehicleMakeOther;
                    existingrecord.VehicleModel = model.VehicleModel;
                    existingrecord.VehicleModelOther = model.VehicleModelOther;
                    existingrecord.VehicleChassis = model.VehicleChassis;
                    existingrecord.VehicleEngine = model.VehicleEngine;
                    existingrecord.VehicleTransmission = model.VehicleTransmission;
                    existingrecord.WarrantyStartDate = model.WarrantyStartDate;
                    existingrecord.WarrantyYears = model.WarrantyYears;
                    existingrecord.WarrantyMiles = model.WarrantyMiles;
                    existingrecord.CurrentMiles = model.CurrentMiles;
                    existingrecord.VehicleID = model.VehicleID;
                    existingrecord.IsFirstOwner = model.IsFirstOwner;
                    
                    //TFS: 129
                    //if ("Vendor".Equals(existingrecord.PayeeType,StringComparison.InvariantCultureIgnoreCase))
                    //{
                        existingrecord.VehicleOwnerName = model.VehicleOwnerName;
                    //}
                    #endregion

                    #region Next Action Region
                    existingrecord.NextActionID = model.NextActionID;
                    existingrecord.NextActionAssignedToUserID = model.NextActionAssignedToUserID;
                    existingrecord.NextActionScheduledDate = model.NextActionScheduledDate;
                    existingrecord.ClaimDescription = model.ClaimDescription;
                    #endregion

                    #region Ford ACES Information
                    existingrecord.GWOApprovalCode = model.GWOApprovalCode;
                    existingrecord.CUDLCaseNumber = model.CUDLCaseNumber;
                    existingrecord.ACESSubmitDate = model.ACESSubmitDate;
                    existingrecord.ACESFeeAmount = model.ACESFeeAmount;
                    existingrecord.ACESOutcome = model.ACESOutcome;
                    #endregion

                    #region When Claim Type is Ford QFC then following fields are not updatable
                    ClaimType claimType = dbContext.ClaimTypes.Where(u => u.ID == model.ClaimTypeID).FirstOrDefault();
                    if (!claimType.Name.Equals("FordQFC"))
                    {
                        existingrecord.ClaimStatusID = model.ClaimStatusID;
                        existingrecord.ClaimCategoryID = model.ClaimCategoryID;
                        existingrecord.ACESClearedDate = model.ACESClearedDate;
                        existingrecord.ACESAmount = model.ACESAmount;
                    }
                    #endregion

                    #region When there is Change in Claim Status either approved or rejected following Fields update is required
                    //Check the Claim Status and set the following fields.
                    ClaimStatu claimStatus = dbContext.ClaimStatus.Where(u => u.ID == model.ClaimStatusID).FirstOrDefault();
                    if (claimStatus.Name.Equals("Approved") || claimStatus.Name.Equals("Rejected"))
                    {
                        existingrecord.ClaimDecisionBy = userName;
                        existingrecord.ClaimDecisionDate = DateTime.Now;
                    }
                    #endregion

                    existingrecord.ACESClaimStatusID = model.ACESClaimStatusID;

                }
                dbContext.SaveChanges();
            }
        }


    }
}
