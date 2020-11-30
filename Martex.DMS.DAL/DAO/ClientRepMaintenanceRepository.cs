using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// ClientRepMaintenanceRepository
    /// </summary>
    public class ClientRepMaintenanceRepository
    {
        /// <summary>
        /// Get the ClientReps list.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<ClientRepList_Result> ClientRepList(PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientRepList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList<ClientRepList_Result>();
            }
        }

        /// <summary>
        /// Gets the ClientRep with specified record identifier.
        /// </summary>
        /// <param name="recordID">The record identifier.</param>
        /// <param name="createIfNotExists">if set to <c>true</c> [create if not exists].</param>
        /// <returns></returns>
        public ClientRep Get(int recordID, bool createIfNotExists = false)
        {
            ClientRep model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ClientReps.Where(u => u.ID == recordID).FirstOrDefault();
            }

            if (model == null && createIfNotExists)
            {
                model = new ClientRep();
            }
            return model;
        }

        /// <summary>
        /// Saves the ClientRep details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="LoggedInUserName">Name of the logged in user.</param>
        public void SaveClientRepDetails(ClientRep model, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.ClientReps.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord == null)
                {
                    model.CreateBy = LoggedInUserName;
                    model.CreateDate = DateTime.Now;
                    model.IsActive = true;
                    dbContext.ClientReps.Add(model);
                }
                else
                {
                    existingRecord.FirstName = model.FirstName;
                    existingRecord.LastName = model.LastName;
                    existingRecord.Title = model.Title;
                    existingRecord.Email = model.Email;
                    existingRecord.PhoneNumber = model.PhoneNumber;
                    existingRecord.MobileNumber = model.MobileNumber;
                    existingRecord.PhoneNumberTypeID = model.PhoneNumberTypeID;
                    existingRecord.Avatar = model.Avatar;
                    existingRecord.ModifyBy = LoggedInUserName;
                    existingRecord.ModifyDate = DateTime.Now;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the ClientRep.
        /// </summary>
        /// <param name="recordID">The record identifier.</param>
        /// <param name="LoggedInUserName">Name of the logged in user.</param>
        public void DeleteClientRep(int recordID, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.ClientReps.Where(u => u.ID == recordID).FirstOrDefault();

                if (existingRecord != null)
                {
                    List<Client> clientList = dbContext.Clients.Where(a => a.ClientRepID == recordID).ToList();

                    foreach (var client in clientList)
                    {
                        client.ClientRepID = null;
                        client.ModifyBy = LoggedInUserName;
                        client.ModifyDate = DateTime.Now;
                        dbContext.SaveChanges();
                    }

                    existingRecord.IsActive = false;
                    existingRecord.ModifyBy = LoggedInUserName;
                    existingRecord.ModifyDate = DateTime.Now;
                    dbContext.SaveChanges();
                }
            }
        }

    }
}
