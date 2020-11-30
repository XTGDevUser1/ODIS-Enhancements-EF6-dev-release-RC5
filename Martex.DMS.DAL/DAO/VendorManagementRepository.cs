using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity.Core.Objects;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public partial class VendorManagementRepository
    {
        #region Public Methods
        /// <summary>
        /// Searches the specified criteria.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<VendorManagementList_Result> Search(PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorManagementList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList();
            }
        }

        /// <summary>
        /// Determines whether [is product rate type configured] [the specified product ID].
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <param name="rateTypeName">Name of the rate type.</param>
        /// <returns>
        ///   <c>true</c> if [is product rate type configured] [the specified product ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsProductRateTypeConfigured(int productID, string rateTypeName)
        {
            bool IsConfigured = true;
            if (productID > 0)
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    RateType rateTypes = dbContext.RateTypes.Where(u => u.IsActive == true && u.Name.Equals(rateTypeName)).FirstOrDefault();
                    if (rateTypes != null)
                    {
                        ProductRateType productRateType = dbContext.ProductRateTypes.Where(u => u.IsActive == true && u.ProductID == productID && u.RateTypeID == rateTypes.ID).FirstOrDefault();
                        if (productRateType == null)
                        {
                            IsConfigured = false;
                        }
                    }
                }
            }
            return IsConfigured;
        }


        /// <summary>
        /// Gets the vendor match.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="DispatchNum">The dispatch num.</param>
        /// <param name="OfficeNum">The office num.</param>
        /// <param name="VendorName">Name of the vendor.</param>
        /// <returns></returns>
        public List<GetVendorInfoSearch_Result> GetVendorMatch(PageCriteria pageCriteria, string DispatchNum, string OfficeNum, string VendorName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetVendorInfoSearch(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, DispatchNum, OfficeNum, VendorName);
                return result.ToList<GetVendorInfoSearch_Result>();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="pageCriteria"></param>
        /// <param name="vendorID"></param>
        /// <returns></returns>
        public List<VendorSummaryLocationRates_Result> GetVendorSummaryLocationRates(PageCriteria pageCriteria, int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetVendorSummaryLocationRates(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, vendorID);
                return result.ToList<VendorSummaryLocationRates_Result>();
            }
        }

        /// <summary>
        /// Adds the vendor.
        /// </summary>
        /// <param name="v">The v.</param>
        public string AddVendor(Vendor v, string sourceSystem = "BackOffice", string status = "Pending")
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                int? nextNumber = dbContext.GetNextNumber("VendorNumber").Single<int?>();
                //NP: Taken StateID into VendorNumber because in the Model there is no variable to assign StateID.
                int stateId = int.Parse(v.VendorNumber);
                string vendorState = (from sp in dbContext.StateProvinces where sp.ID == stateId select sp.Abbreviation).FirstOrDefault();

                vendorState = vendorState ?? string.Empty;

                v.VendorNumber = vendorState.Trim() + nextNumber.ToString();
                vendorState = v.VendorNumber;

                v.SourceSystemID = (from ss in dbContext.SourceSystems where ss.Name == sourceSystem select ss.ID).FirstOrDefault();
                v.VendorStatusID = (from vs in dbContext.VendorStatus where vs.Name == status select vs.ID).FirstOrDefault();

                dbContext.Vendors.Add(v);
                dbContext.SaveChanges();
                return vendorState;

            }
        }

        /// <summary>
        /// Adds the vendor location.
        /// </summary>
        /// <param name="vl">The vl.</param>
        public void AddVendorLocation(VendorLocation vl)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorLocations.Add(vl);
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Gets the name of the vendor location status by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public VendorLocationStatu GetVendorLocationStatusByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.VendorLocationStatus.Where(x => x.Name == name).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Adds the vendor status log.
        /// </summary>
        /// <param name="vsl">The VSL.</param>
        public void AddVendorStatusLog(VendorStatusLog vsl)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorStatu pendingStatus = dbContext.VendorStatus.Where(u => u.Name.Equals("Pending")).FirstOrDefault();
                VendorStatusReason reason = dbContext.VendorStatusReasons.Where(u => u.Name.Equals("NewVendor")).FirstOrDefault();
                if (pendingStatus == null)
                {
                    throw new DMSException(string.Format("Unable to find the Vendor Status Configuration for {0}", "Pending"));
                }

                if (reason == null)
                {
                    throw new DMSException(string.Format("Unable to find the Vendor Status Reason Configuration for {0}", "VendorAdd"));
                }
                vsl.VendorStatusIDAfter = pendingStatus.ID;
                vsl.VendorStatusReasonID = reason.ID;
                dbContext.VendorStatusLogs.Add(vsl);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the vendor user.
        /// </summary>
        /// <param name="aspnetUserID">The aspnet user ID.</param>
        /// <returns></returns>
        public VendorUser GetVendorUser(Guid aspnetUserID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendorUser = dbContext.VendorUsers.Include("Vendor").Where(x => x.aspnet_UserID == aspnetUserID).FirstOrDefault();
                return vendorUser;
            }
        }


        #region Vendor Location
        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorLocations_Result> GetVendorLocations(PageCriteria pageCriteria, int? vendorID, bool ifVendorInformation)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorLocations_Result> vendorLoactions = dbContext.GetVendorLocations(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, vendorID).ToList<VendorLocations_Result>();
                if (ifVendorInformation)
                {
                    VendorLocations_Result vl = new VendorLocations_Result()
                    {
                        VendorLocation = 0,
                        LocationAddress = "Vendor Information"
                    };
                    vendorLoactions.Insert(0, vl);
                }
                return vendorLoactions;
            }
        }

        /// <summary>
        /// Deletes the vendor location.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        public void DeleteVendorLocation(int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var asTransactionCount = dbContext.VendorLocationPaymentTypes.Where(a => a.VendorLocationID == vendorLocationID).Count();
                var locationProductCount = dbContext.VendorLocationProducts.Where(a => a.VendorLocationID == vendorLocationID).Count();
                var postalCodeCount = dbContext.VendorLocationPostalCodes.Where(a => a.VendorLocationID == vendorLocationID).Count();
                var vendorLocation = dbContext.VendorLocations.Where(a => a.ID == vendorLocationID).FirstOrDefault();

                if (asTransactionCount > 0 || locationProductCount > 0 || postalCodeCount > 0)
                {
                    vendorLocation.IsActive = false;
                    dbContext.Entry(vendorLocation).State = EntityState.Modified;

                }
                else
                {
                    dbContext.Entry(vendorLocation).State = EntityState.Deleted;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the vendor location address.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public VendorLocationAddress_Result GetVendorLocationAddress(int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorLocationAddress_Result add = dbContext.GetVendorLocationAddress(vendorLocationID).FirstOrDefault();
                return add;
            }
        }

        /// <summary>
        /// Gets the vendor locations list.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorLocationsList_Result> GetVendorLocationsList(int VendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationsList(VendorID).ToList<VendorLocationsList_Result>();
            }
        }
        #endregion

        /// <summary>
        /// Gets the name of the state.
        /// </summary>
        /// <param name="stateID">The state ID.</param>
        /// <returns></returns>
        public string GetStateName(int? stateID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                StateProvince state = dbContext.StateProvinces.Where(s => s.ID == stateID).FirstOrDefault();
                string stateName = string.Format("{0} - {1}", state.Abbreviation.Trim(), state.Name.Trim());
                return stateName;
            }
        }

        #region Vendor PO Details
        /// <summary>
        /// Gets the vendor PO details.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorPOList_Result> GetVendorPODetails(PageCriteria pageCriteria, int VendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorPOList(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, VendorID).ToList<VendorPOList_Result>();
            }
        }
        #endregion

        #region Vendor Location PO Details

        /// <summary>
        /// Gets the vendor location PO details.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationPOList_Result> GetVendorLocationPODetails(PageCriteria pageCriteria, int VendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationPOList(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, VendorLocationID).ToList<VendorLocationPOList_Result>();
            }
        }
        #endregion

        #region Vendor Activity
        /// <summary>
        /// Gets the vendor activity list.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorActivityList_Result> GetVendorActivityList(int? vendorID, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorActivityList(vendorID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the vendor activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveVendorActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "Vendor").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }
        #endregion

        #region Vendor Location Activity
        /// <summary>
        /// Gets the vendor location activity list.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorLocationActivityList_Result> GetVendorLocationActivityList(int? vendorLocationID, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationActivityList(vendorLocationID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorLocationActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the vendor location activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveVendorLocationActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "VendorLocation").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }
        #endregion

        /// <summary>
        /// Creates the vendor status log.
        /// </summary>
        /// <param name="model">The model.</param>
        public void CreateVendorStatusLog(VendorStatusLog model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorStatusLogs.Add(model);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the vendor location payment types.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationPaymentType> GetVendorLocationPaymentTypes(int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorLocationPaymentTypes.Where(u => u.VendorLocationID == vendorLocationID).ToList();
            }
        }

        /// <summary>
        /// Deletes the type of the vendor location payment.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        public void DeleteVendorLocationPaymentType(int recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.VendorLocationPaymentTypes.Where(u => u.ID == recordID).FirstOrDefault();
                if (existingRecord != null)
                {
                    dbContext.Entry(existingRecord).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }

        }
        /// <summary>
        /// Adds the type of the vendor location payment.
        /// </summary>
        /// <param name="model">The model.</param>
        public void AddVendorLocationPaymentType(VendorLocationPaymentType model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorLocationPaymentTypes.Add(model);
                dbContext.Entry(model).State = EntityState.Added;
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Adds the type of the vendor location payment.
        /// </summary>
        /// <param name="model">The model.</param>
        public void AddVendorLocationPaymentType(VendorLocationPaymentType model, string paymentType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var pt = dbContext.PaymentTypes.Where(x => x.Name.Equals(paymentType, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (pt == null)
                {
                    throw new DMSException(string.Format("Payment type {0} not set up in the system", paymentType));
                }
                model.PaymentTypeID = pt.ID;
                dbContext.VendorLocationPaymentTypes.Add(model);
                dbContext.Entry(model).State = EntityState.Added;
                dbContext.SaveChanges();
            }

        }


        /// <summary>
        /// Gets the vendor ACH details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorACH GetVendorACHDetails(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorACHes.Where(u => u.VendorID == vendorID && u.IsActive == true).FirstOrDefault();
            }
        }

        /// <summary>
        /// Saves the vendo ACH details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public int SaveVendoACHDetails(VendorACH model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //TFS:475
                var existingDetails = dbContext.VendorACHes.Where(u => u.VendorID == model.VendorID && u.IsActive == true).FirstOrDefault();

                if (existingDetails == null)
                {
                    var sourceSystem = dbContext.SourceSystems.Where(u => u.Name.Equals(SourceSystemName.BACK_OFFICE)).FirstOrDefault();
                    if (sourceSystem == null)
                    {
                        throw new DMSException(string.Format("Unable to retrieve configuration for {0}", SourceSystemName.BACK_OFFICE));
                    }
                    model.IsActive = true;
                    model.SourceSystemID = sourceSystem.ID;
                    model.CreateBy = userName;
                    model.CreateDate = DateTime.Now;
                    model.IsACHSecurityBlock = null;
                    model.ACHSecurityBlockNumber = null;
                    dbContext.VendorACHes.Add(model);
                }
                else
                {
                    existingDetails.ModifyBy = userName;
                    existingDetails.ModifyDate = DateTime.Now;
                    existingDetails.NameOnAccount = model.NameOnAccount;
                    existingDetails.AccountNumber = model.AccountNumber;
                    existingDetails.AccountType = model.AccountType;
                    existingDetails.BankName = model.BankName;
                    existingDetails.BankABANumber = model.BankABANumber;
                    existingDetails.ACHStatusID = model.ACHStatusID;
                    existingDetails.ReceiptContactMethodID = model.ReceiptContactMethodID;
                    existingDetails.ReceiptEmail = model.ReceiptEmail;
                    existingDetails.IsVoidedCheckOnFile = model.IsVoidedCheckOnFile;
                    existingDetails.IsACHSecurityBlock = null;
                    existingDetails.ACHSecurityBlockNumber = null;

                    // Bank Address Details
                    existingDetails.BankAddressLine1 = model.BankAddressLine1;
                    existingDetails.BankAddressLine2 = model.BankAddressLine2;
                    existingDetails.BankAddressLine3 = model.BankAddressLine3;
                    existingDetails.BankAddressCity = model.BankAddressCity;
                    existingDetails.BankAddressPostalCode = model.BankAddressPostalCode;

                    existingDetails.BankAddressCountryID = model.BankAddressCountryID;
                    existingDetails.BankAddressCountryCode = model.BankAddressCountryCode;

                    existingDetails.BankAddressStateProvinceID = model.BankAddressStateProvinceID;
                    existingDetails.BankAddressStateProvince = model.BankAddressStateProvince;

                    // Phone Number Details
                    existingDetails.BankPhoneNumber = model.BankPhoneNumber;
                }
                dbContext.SaveChanges();

            }
            return model.ID;
        }

        #region Vendor Service

        /// <summary>
        /// Gets the vendor services repair list.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorServices_Result> GetVendorServices(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorServices(vendorID).ToList<VendorServices_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor portal services.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public List<VendorPortalServicesList_Result> GetVendorPortalServices(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorPortalServicesList(vendorID).ToList<VendorPortalServicesList_Result>();
            }
        }

        /// <summary>
        /// Saves the vendor services.
        /// </summary>
        /// <param name="vendorID">The vendor unique identifier.</param>
        /// <param name="services">The services.</param>
        /// <param name="createDate">The create date.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveVendorServices(int vendorID, List<string> services, DateTime? createDate, string createBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveVendorProducts(vendorID, string.Join(",", services.ToArray()), createBy);
            }
        }

        #endregion


        #endregion




    }
}
