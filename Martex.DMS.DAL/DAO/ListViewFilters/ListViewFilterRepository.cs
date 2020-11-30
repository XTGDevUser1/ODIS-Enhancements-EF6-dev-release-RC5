using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;


namespace Martex.DMS.DAL.DAO.ListViewFilters
{
    public class ListViewFilterRepository
    {
        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Save(ListViewFilter model, string userName)
        {
            model.CreateBy = userName;
            model.CreateDate = DateTime.Now;
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ListViewFilters.Add(model);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the specified record ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="userName">Name of the user.</param>
        public void Delete(int recordID, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.ListViewFilters.Where(u => u.ID == recordID && u.IsActive == true).FirstOrDefault();
                if (existingRecord != null)
                {
                    dbContext.ListViewFilters.Remove(existingRecord);
                    dbContext.SaveChanges();
                }
                
            }
        }

        /// <summary>
        /// Gets the specified record ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ListViewFilter Get(int recordID)
        {
            ListViewFilter model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ListViewFilters.Where(u => u.ID == recordID && u.IsActive == true).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve List View Filters ID {0}", recordID));
            }
            return model;
        }

        /// <summary>
        /// Gets the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pagename">The pagename.</param>
        /// <returns></returns>
        public List<ListViewFilter> Get(Guid userId,string pagename)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ListViewFilters.Where(u => u.aspnet_UserID == userId && u.PageName.Equals(pagename) && u.IsActive == true).OrderBy(u => u.Sequence).ToList();
            }
        }
    }
}
