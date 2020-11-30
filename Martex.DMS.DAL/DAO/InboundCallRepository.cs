using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class InboundCallRepository
    {
        /// <summary>
        /// Adds the specified inbound call.
        /// </summary>
        /// <param name="inboundCall">The inbound call.</param>
        /// <returns></returns>
        public int Add(InboundCall inboundCall)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.InboundCalls.Add(inboundCall);
                dbContext.SaveChanges();

                return inboundCall.ID;
            }
        }
        /// <summary>
        /// Saves the specified inbound call.
        /// </summary>
        /// <param name="inboundCall">The inbound call.</param>
        public void Save(InboundCall inboundCall)
        {
            // Make Sure that while Saving Data Record Should Not have values as Zero
            if (inboundCall.ContactPhoneTypeID.GetValueOrDefault() == 0)
            {
                inboundCall.ContactPhoneTypeID = null;
            }
            if (inboundCall.ContactAltPhoneTypeID.GetValueOrDefault() == 0)
            {
                inboundCall.ContactAltPhoneTypeID = null;
            }
            using (DMSEntities dbContext = new DMSEntities())
            {

                if (inboundCall.ID > 0)
                {
                    InboundCall record = dbContext.InboundCalls.Where(x => x.ID == inboundCall.ID).FirstOrDefault();
                    record.MemberID = inboundCall.MemberID;
                    record.CaseID = inboundCall.CaseID;
                    record.ProgramID = inboundCall.ProgramID;
                    record.CallTypeID = inboundCall.CallTypeID;
                    record.Language = inboundCall.Language;
                    record.IsSafe = inboundCall.IsSafe;
                    record.ContactPhoneTypeID = inboundCall.ContactPhoneTypeID;
                    record.ContactPhoneNumber = inboundCall.ContactPhoneNumber;
                    
                    record.ContactAltPhoneNumber = inboundCall.ContactAltPhoneNumber;
                    record.ContactAltPhoneTypeID = inboundCall.ContactAltPhoneTypeID;

                    record.ModifyBy = inboundCall.ModifyBy;
                    record.ModifyDate = inboundCall.ModifyDate;
                    
                }
                else
                {
                    dbContext.InboundCalls.Add(inboundCall);
                }

                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Gets the contact category ID.
        /// </summary>
        /// <param name="callTypeId">The call type id.</param>
        /// <returns></returns>
        public int? GetContactCategoryID(int callTypeId)
        {
            int? contactCategoryId=null;
            using (DMSEntities dbContext = new DMSEntities())
            {
               CallType cType= dbContext.CallTypes.Where(c => c.ID == callTypeId).FirstOrDefault<CallType>();
               if (cType != null)
               {
                   contactCategoryId= cType.ContactCategoryID;
               }
            }

            return contactCategoryId;
        }
        /// <summary>
        /// Gets the inbound call by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public InboundCall GetInboundCallById(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
              InboundCall inCall=  dbContext.InboundCalls.Where(i => i.ID == id).FirstOrDefault<InboundCall>();
              return inCall;
            }
        }
        /// <summary>
        /// Gets the inbound call by case id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public InboundCall GetInboundCallByCaseId(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                InboundCall inCall = dbContext.InboundCalls.Where(i => i.CaseID == id).FirstOrDefault<InboundCall>();
                return inCall;
            }
        }

        /// <summary>
        /// Gets the last inbound call by case id.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        public InboundCall GetLastInboundCallByCaseId(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                InboundCall inCall = dbContext.InboundCalls.Where(i => i.CaseID == id).OrderByDescending(a=>a.CreateDate).FirstOrDefault<InboundCall>();
                return inCall;
            }
        }


        /// <summary>
        /// Sets the member ID.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="memberID">The member ID.</param>
        public void SetMemberID(int inboundCallId, int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var inCall = dbContext.InboundCalls.Where(x => x.ID == inboundCallId).FirstOrDefault();
                if (inCall != null)
                {
                    inCall.MemberID = memberID;                    
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Sets the mobile ID.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="mobileRecorId">The mobile recor id.</param>
        public void SetMobileID(int inboundCallId,int mobileRecorId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var inCall = dbContext.InboundCalls.Where(x => x.ID == inboundCallId).FirstOrDefault();
                if (inCall != null)
                {                    
                    inCall.MobileID = mobileRecorId;
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Updates the case phone location with case ID.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="caseID">The case ID.</param>
        public void UpdateCasePhoneLocationWithCaseID(int inboundCallId, int caseID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var cpl = dbContext.CasePhoneLocations.Where(x => x.InboundCallID == inboundCallId).FirstOrDefault();
                if (cpl != null)
                {
                    cpl.CaseID = caseID;
                    dbContext.SaveChanges();
                }
            }
        }

    }
}
