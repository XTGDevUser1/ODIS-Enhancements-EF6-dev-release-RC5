using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;
using Martex.DMS.DAL.Entities;
using System.Web.Mvc;

namespace Martex.DMS.DAL.DAO
{
    public class CustomerFeedbackRepository
    {

        /// <summary>
        /// Gets the QA concern type list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<dms_CustomerFeedback_list_Result> GetCustomerfeedbackdata(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<dms_CustomerFeedback_list_Result>();
            }
        }

        public CustomerFeedback GetCustomerFeedbackById(int? customerFeedBackId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CustomerFeedback customerfeedback = dbContext.CustomerFeedbacks.Where(u => u.ID == customerFeedBackId).FirstOrDefault();
                return customerfeedback;
            }

        }
        public void UpdateCustomerSurvey(int surveyId, string userAction, string sessionId, string loggedInUser, string eventSource)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.UpdateCustomerSurvey(surveyId, userAction, sessionId, loggedInUser, eventSource);
            }
        }

        public string GetCustomerFeedbackTypeForFeedback(int? customerFeedBackId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                string feedbackType = dbContext.CustomerFeedbackDetails.Include(a => a.CustomerFeedbackType)
                    .Where(u => u.CustomerFeedbackID == customerFeedBackId).Select(a => a.CustomerFeedbackType.Description).FirstOrDefault();
                return feedbackType;
            }

        }
        
        public int GetPrioritiesBySource(int? SourceId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                int ProrityId = dbContext.CustomerFeedbackSourcePriorities.Where(u => u.CustomerFeedbackSourceID == SourceId).Select(a => a.CustomerFeedbackPriorityID).FirstOrDefault();
                return ProrityId;
            }

        }

        /// <summary>
        /// Gets the customer feedback by a number type
        /// </summary>
        /// <param name="numberType">Number type - possible values - ServiceRequest / PurchaseOrder.</param>
        /// <param name="numberValue">The number value.</param>
        /// <returns></returns>
        public List<GetCustomerFeedbackHeaderBySROrPO_Result> GetCustomerFeedbackBy(string numberType, string numberValue)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackHeaderBySROrPO(numberType, numberValue).ToList<GetCustomerFeedbackHeaderBySROrPO_Result>();
            }
        }

        public void Save(CustomerFeedback customerFeedback)
        {
            using (var dbContext = new DMSEntities())
            {
                if (customerFeedback.ID == 0)
                {
                    dbContext.CustomerFeedbacks.Add(customerFeedback);
                }
                else
                {
                    var existingRecord = dbContext.CustomerFeedbacks.Where(c => c.ID == customerFeedback.ID).FirstOrDefault();
                    if (existingRecord != null)
                    {
                        //TODO: Update the existing record                        
                        existingRecord.ServiceRequestID = customerFeedback.ServiceRequestID;
                        existingRecord.CustomerFeedbackStatusID = customerFeedback.CustomerFeedbackStatusID;
                        existingRecord.CustomerFeedbackPriorityID = customerFeedback.CustomerFeedbackPriorityID;
                        existingRecord.CustomerFeedbackSourceID = customerFeedback.CustomerFeedbackSourceID;
                        existingRecord.NextActionID = customerFeedback.NextActionID;
                        existingRecord.NextActionAssignedToUserID = customerFeedback.NextActionAssignedToUserID;
                        existingRecord.NextActionScheduleDate = customerFeedback.NextActionScheduleDate;
                        existingRecord.Description = customerFeedback.Description;
                        existingRecord.ReceiveDate = customerFeedback.ReceiveDate;
                        existingRecord.MemberFirstName = customerFeedback.MemberFirstName;
                        existingRecord.MemberLastName = customerFeedback.MemberLastName;
                        existingRecord.CallRecordingNumber = customerFeedback.CallRecordingNumber;
                        existingRecord.CreateDate = customerFeedback.CreateDate;
                        existingRecord.CreateBy = customerFeedback.CreateBy;
                        existingRecord.ModifyDate = customerFeedback.ModifyDate;
                        existingRecord.ModifyBy = customerFeedback.ModifyBy;
                        existingRecord.MemberAddressLine1 = customerFeedback.MemberAddressLine1;
                        existingRecord.MemberAddressLine2 = customerFeedback.MemberAddressLine2;
                        existingRecord.MemberAddressLine3 = customerFeedback.MemberAddressLine3;
                        existingRecord.MemberAddressCity = customerFeedback.MemberAddressCity;
                        existingRecord.MemberAddressStateProvince = customerFeedback.MemberAddressStateProvince;
                        existingRecord.MemberAddressStateProvinceID = customerFeedback.MemberAddressStateProvinceID;
                        existingRecord.MemberAddressPostalCode = customerFeedback.MemberAddressPostalCode;
                        existingRecord.MemberAddressCountryCode = customerFeedback.MemberAddressCountryCode;
                        existingRecord.MemberAddressCountryID = customerFeedback.MemberAddressCountryID;
                        existingRecord.MemberPhoneNumber = customerFeedback.MemberPhoneNumber;
                        existingRecord.MemberEmail = customerFeedback.MemberEmail;
                        existingRecord.DueDate = customerFeedback.DueDate;
                        existingRecord.WorkedByUserID = customerFeedback.WorkedByUserID;

                        //SR: Update customer feedback research complate and close date based on the status.
                        if (existingRecord.CustomerFeedbackStatusID.HasValue)
                        {
                            CustomerFeedbackStatu customerFeedbackStatus = GetCustomerFeedbackStatusById(customerFeedback.CustomerFeedbackStatusID.Value);

                            if (customerFeedbackStatus != null)
                            {
                                if (customerFeedbackStatus.Name == CustomerFeedbackStatusNames.RESEARCH_COMPLETED && existingRecord.ResearchComplete == null)
                                {
                                    existingRecord.ResearchComplete = DateTime.Now;
                                }

                                if (customerFeedbackStatus.Name == CustomerFeedbackStatusNames.CLOSED && existingRecord.ClosedDate == null)
                                {
                                    existingRecord.ClosedDate = DateTime.Now;
                                }
                            }
                        }

                        dbContext.Entry(existingRecord).State = EntityState.Modified;
                    }
                }
                dbContext.SaveChanges();
            }
        }


        public List<CustomerFeedbackActivityList_Result> GetCustomerFeedbackActivityList(PageCriteria pc, int customerFeedbackID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackActivityList(customerFeedbackID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<CustomerFeedbackActivityList_Result>();
            }
        }

        /// <summary>
        /// Saves the Customer Feedback activity comments.
        /// </summary>
        /// <param name="comment">The comment.</param>
        public void SaveCustomerFeedbackActivityComments(Comment comment)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                comment.EntityID = dbContext.Entities.Where(a => a.Name == "CustomerFeedback").Select(a => a.ID).FirstOrDefault();
                dbContext.Comments.Add(comment);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Get CustomerFeedback Details by customer feedback id
        /// </summary>
        /// <param name="pc"></param>
        /// <param name="customerFeedbackId">Customer feedback Id</param>
        /// <returns></returns>
        public List<GetCustomerFeedbackDetails_Result> GetCustomerFeedbackDetails(PageCriteria pc, int customerFeedbackId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackDetails(customerFeedbackId, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, pc.WhereClause).ToList<GetCustomerFeedbackDetails_Result>();
            }

        }

        /// <summary>
        /// Get vendor by po number
        /// </summary>
        /// <param name="purchaseOrderNumber">po number</param>
        /// <returns></returns>
        public Vendor GetVendorByPurchaseOrderNumber(string purchaseOrderNumber)
        {
            using (var dbContext = new DMSEntities())
            {
                var results = (from v in dbContext.Vendors
                               join vl in dbContext.VendorLocations on v.ID equals vl.VendorID
                               join p in dbContext.PurchaseOrders on vl.ID equals p.VendorLocationID
                               where p.PurchaseOrderNumber == purchaseOrderNumber
                               orderby v.Name
                               select v
                               ).FirstOrDefault<Vendor>();
                return results;
            }
        }

        public int GetCustomerFeedbackStatus(int customerFeedbackID, int? CustomerFeedbackStatusID)
        {
            int? statusid = 0;

            using (DMSEntities dbContext = new DMSEntities())
            {
                statusid = dbContext.CustomerFeedbacks.Where(a => a.ID == customerFeedbackID).Select(a => a.CustomerFeedbackStatusID).FirstOrDefault();
                //openstatusID = dbContext.CustomerFeedbackStatus.Where(a => a.Name == "Open").Select(a => a.ID).FirstOrDefault();
            }


            return Convert.ToInt32(statusid);

        }

        public CustomerFeedbackStatu GetCustomerFeedbackStatusById(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbackStatus.Where(a => a.ID == id).FirstOrDefault();
            }
        }

        public void SaveCustomerFeedbackStatusChangeLog(int customerFeedbackID, string loggedInUserId, int? oldstatusid, int? newstatusid)
        {
            CustomerFeedbackStatusChangeLog model = new CustomerFeedbackStatusChangeLog();
            model.CustomerFeedbackID = customerFeedbackID;
            model.CreateBy = loggedInUserId;
            model.CreateDate = DateTime.Now;
            model.FromCustomerFeedbackStatusID = oldstatusid.GetValueOrDefault();
            model.ToCustomerFeedbackStatusID = newstatusid.GetValueOrDefault();

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.CustomerFeedbackStatusChangeLogs.Add(model);
                dbContext.SaveChanges();

            }
        }


        //public int GetStatusClosedstatusid()
        //{
        //    int closedstatusid = 0;
        //    using (DMSEntities dbContext = new DMSEntities())
        //    {
        //        closedstatusid = dbContext.CustomerFeedbackStatus.Where(a => a.Name == "Closed").Select(a => a.ID).FirstOrDefault();
        //    }

        //    return closedstatusid;
        //}

        /// <summary>
        /// Save Customer Feedback Details
        /// </summary>
        /// <param name="customerFeedbackDetails">model</param>
        /// <param name="loggedInUserId">logged in userId</param>
        public void SaveCustomerFeedbackDetails(CustomerFeedbackDetail customerFeedbackDetails, string LoggedInUserName)
        {
            using (var dbContext = new DMSEntities())
            {
                if (customerFeedbackDetails.ID == 0)
                {
                    customerFeedbackDetails.CreateDate = DateTime.Now;
                    customerFeedbackDetails.CreateBy = LoggedInUserName;

                    dbContext.CustomerFeedbackDetails.Add(customerFeedbackDetails);
                }
                else
                {
                    var existingRecord = dbContext.CustomerFeedbackDetails.Where(c => c.ID == customerFeedbackDetails.ID).FirstOrDefault();
                    if (existingRecord != null)
                    {
                        //TODO: Update the existing record
                        existingRecord.CustomerFeedbackTypeID = customerFeedbackDetails.CustomerFeedbackTypeID;
                        existingRecord.CustomerFeedbackCategoryID = customerFeedbackDetails.CustomerFeedbackCategoryID;
                        existingRecord.CustomerFeedbackSubCategoryID = customerFeedbackDetails.CustomerFeedbackSubCategoryID;
                        existingRecord.ResolutionDescription = customerFeedbackDetails.ResolutionDescription;
                        existingRecord.UserID = customerFeedbackDetails.UserID;
                        existingRecord.VendorLocationID = customerFeedbackDetails.VendorLocationID;
                        existingRecord.IsInvalid = customerFeedbackDetails.IsInvalid;
                        existingRecord.CustomerFeedbackInvalidReasonID = customerFeedbackDetails.CustomerFeedbackInvalidReasonID;
                        existingRecord.ModifyDate = DateTime.Now;
                        existingRecord.ModifyBy = LoggedInUserName;

                        dbContext.Entry(existingRecord).State = EntityState.Modified;
                    }
                }
                dbContext.SaveChanges();
            }
        }

        public List<CustomerFeedbackSurveyList_Result> GetCustomerFeedbackSurveyList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackSurveyList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<CustomerFeedbackSurveyList_Result>();
            }
        }

        public void LockCustomerFeedback(int customerFeedbackId, int? assignedToUserID)
        {
            using (var dbContext = new DMSEntities())
            {
                var customerFeedback = dbContext.CustomerFeedbacks.Where(x => x.ID == customerFeedbackId).FirstOrDefault();
                if (customerFeedback != null)
                {
                    customerFeedback.AssignedToUserID = assignedToUserID;
                    dbContext.SaveChanges();
                }
            }
        }

        public void UnlockCustomerFeedback(int customerFeedbackId)
        {
            using (var dbContext = new DMSEntities())
            {
                var customerFeedback = dbContext.CustomerFeedbacks.Where(x => x.ID == customerFeedbackId).FirstOrDefault();
                if (customerFeedback != null)
                {
                    customerFeedback.AssignedToUserID = null;
                    dbContext.SaveChanges();
                }
            }
        }


        public CustomerSurveySample GetCustomerFeedbackSurvey(int id)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.CustomerSurveySamples.Where(a => a.ID == id).FirstOrDefault();
            }
        }


        public void UpdateCustomerSurveyDecidedDetails(CustomerSurveySample survey, string loggedInUser)
        {
            using (var dbContext = new DMSEntities())
            {
                var existingCustomerSurvey = dbContext.CustomerSurveySamples.Where(a => a.ID == survey.ID).FirstOrDefault();
                if (existingCustomerSurvey != null)
                {
                    existingCustomerSurvey.DecidedBy = survey.DecidedBy;
                    existingCustomerSurvey.DecidedDate = survey.DecidedDate;
                    existingCustomerSurvey.CustomerFeedbackID = survey.CustomerFeedbackID;
                    existingCustomerSurvey.IsIgnore = survey.IsIgnore;


                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Get Customer Details By Id
        /// </summary>
        /// <param name="customerDetailId">CustomerDetailId</param>
        /// <returns></returns>
        public CustomerFeedbackDetail GetCustomerDetailsById(int customerDetailId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CustomerFeedbackDetail details = dbContext.CustomerFeedbackDetails.Where(a => a.ID == customerDetailId).FirstOrDefault();
                return details;
            }
        }

        /// <summary>
        /// Delete Customer Feedback details
        /// </summary>
        /// <param name="customerFeedbackDetailId"> Feedback detail id</param>
        public void DeleteCustomerFeedbackDetails(int customerFeedbackDetailId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CustomerFeedbackDetail details = dbContext.CustomerFeedbackDetails.Where(a => a.ID == customerFeedbackDetailId).FirstOrDefault();
                if (details != null)
                {
                    dbContext.Entry(details).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Get Users or Vendors
        /// </summary>
        /// <returns></returns>
        public List<DropDownEntityForString> GetUsersOrVendors(string categoryName)
        {
            List<DropDownEntityForString> list = new List<DropDownEntityForString>();
            using (DMSEntities dbConext = new DMSEntities())
            {
                if (categoryName == "Agent" || categoryName == "Tech")
                {
                    list = dbConext.Users.Include(a => a.aspnet_Users).Where(u => u.aspnet_Users.aspnet_Applications.ApplicationName == "DMS").Select(m => new DropDownEntityForString
                    {
                        Value = m.ID.ToString(),
                        Text = m.aspnet_Users.UserName
                    })
                    .Distinct()
                    .OrderBy(u => u.Text)
                    .ToList();
                }

                //if (categoryName == "ISP")
                //{
                //    list = dbConext.Vendors.Select(m => new DropDownEntityForString
                //    {
                //        Value = m.ID.ToString(),
                //        Text = m.Name
                //    })
                //    .Distinct()
                //    .OrderBy(u => u.Text)
                //    .ToList();
                //}               
            }

            return list;
        }

        public Vendor GetVendorById(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Vendors.Where(a => a.ID == id).FirstOrDefault();
            }
        }

        /// <summary>
        /// Get Users by application config settings
        /// </summary>
        /// <param name="appConfigName"> Application Configuration Name</param>
        /// <returns></returns>
        public List<dms_Users_By_Appconfig_Role_Setting_Get_Result> GetUsersByAppConfigSettings(string appConfigName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetUsersByAppconfigRoleSetting(appConfigName).ToList<dms_Users_By_Appconfig_Role_Setting_Get_Result>();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="serviceRequestId"> service request id</param>
        /// <returns></returns>
        public bool IsCustomerFeedbackExistsForSR(int? serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.CustomerFeedbacks.Where(u => u.ServiceRequestID == serviceRequestId).Any();
            }
        }

        #region Customer Feedback Gift Card
        /// <summary>
        /// Get CustomerFeedback Gift Card by customer feedback id
        /// </summary>
        /// <param name="pc"></param>
        /// <param name="customerFeedbackId">Customer feedback Id</param>
        /// <returns></returns>
        public List<GetCustomerFeedbackGiftCard_Result> GetCustomerFeedbackGiftCard(PageCriteria pc, int customerFeedbackId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCustomerFeedbackGiftCard(pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, pc.WhereClause, customerFeedbackId).ToList<GetCustomerFeedbackGiftCard_Result>();
            }

        }

        /// <summary>
        /// Save customer feedback gift card 
        /// </summary>
        /// <param name="customerFeedbackGiftCard">model</param>
        /// <param name="loggedInUserId">current user id</param>
        public void SaveCustomerFeedbackGiftCard(CustomerFeedbackGiftCard customerFeedbackGiftCard, string LoggedInUserName)
        {
            using (var dbContext = new DMSEntities())
            {
                if (customerFeedbackGiftCard.ID == 0)
                {
                    customerFeedbackGiftCard.CreateDate = DateTime.Now;
                    customerFeedbackGiftCard.CreateBy = LoggedInUserName;

                    dbContext.CustomerFeedbackGiftCards.Add(customerFeedbackGiftCard);
                }
                else
                {
                    var existingRecord = dbContext.CustomerFeedbackGiftCards.Where(c => c.ID == customerFeedbackGiftCard.ID).FirstOrDefault();
                    if (existingRecord != null)
                    {
                        //TODO: Update the existing record
                        existingRecord.CustomerFeedbackID = customerFeedbackGiftCard.CustomerFeedbackID;
                        existingRecord.CardNumber = customerFeedbackGiftCard.CardNumber;
                        existingRecord.CardAmount = customerFeedbackGiftCard.CardAmount;
                        existingRecord.RequestedBy = customerFeedbackGiftCard.RequestedBy;
                        existingRecord.CardSentDate = customerFeedbackGiftCard.CardSentDate;
                        existingRecord.ModifyDate = DateTime.Now;
                        existingRecord.ModifyBy = LoggedInUserName;

                        dbContext.Entry(existingRecord).State = EntityState.Modified;
                    }
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Get Customer Gift Card By Id
        /// </summary>
        /// <param name="customerFeedbackGiftCardId">Feedback gift card id</param>
        /// <returns></returns>
        public CustomerFeedbackGiftCard GetCustomerFeedbackGiftCardById(int customerFeedbackGiftCardId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CustomerFeedbackGiftCard giftCard = dbContext.CustomerFeedbackGiftCards.Where(a => a.ID == customerFeedbackGiftCardId).FirstOrDefault();
                return giftCard;
            }
        }

        /// <summary>
        /// Delete Customer Feedback Gift Card
        /// </summary>
        /// <param name="customerFeedbackGiftCardId"> Feedback gift card id</param>
        public void DeleteCustomerFeedbackGiftCard(int customerFeedbackGiftCardId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                CustomerFeedbackGiftCard details = dbContext.CustomerFeedbackGiftCards.Where(a => a.ID == customerFeedbackGiftCardId).FirstOrDefault();
                if (details != null)
                {
                    dbContext.Entry(details).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Update customer feedback status pending to open
        /// </summary>
        /// <param name="customerFeedBackId">feedback record id</param>
        /// <param name="customerFeedbackStatusId">feed back new status id</param>
        public void UpdateCustomerFeedbackStatusToOpen(int customerFeedBackId, int customerFeedbackStatusId)
        {
            using (var dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.CustomerFeedbacks.Where(c => c.ID == customerFeedBackId).FirstOrDefault();
                if (existingRecord != null)
                {
                    existingRecord.CustomerFeedbackStatusID = customerFeedbackStatusId;
                    existingRecord.StartDate = DateTime.Now;
                    dbContext.Entry(existingRecord).State = EntityState.Modified;
                }

                dbContext.SaveChanges();
            }
        }
        #endregion
    }
}

