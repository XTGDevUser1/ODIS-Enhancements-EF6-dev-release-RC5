using Martex.DMS.DAL.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Transactions;

namespace Martex.DMS.DAL.DAO
{
    public class PortletsRepository
    {
        /// <summary>
        /// Returns Portlet
        /// </summary>
        /// <param name="portletID"></param>
        /// <returns></returns>
        public Portlet Get(int portletID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Portlets.Where(u => u.ID == portletID).FirstOrDefault();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public PortletModel GetPortletModel(Guid loggedInUserID, string screenName)
        {
            PortletModel model = new PortletModel();
            using (DMSEntities dbContext = new DMSEntities())
            {
                model.Sections = dbContext.PortletSections.Include("PortletColumns").ToList(); 
                model.Portlets = dbContext.GetDashboardPortlets(loggedInUserID).ToList();
            }
            return model;
        }

        /// <summary>
        /// Save DashBoard Portlets Positions
        /// </summary>
        /// <param name="positions"></param>
        /// <param name="eventSource"></param>
        public void Save(List<PortletPositionsModel> positions, string userName, Guid userId)
        {
            if (positions != null && positions.Count > 0)
            {
                using (var transaction = new TransactionScope())
                {

                    using (DMSEntities dbContext = new DMSEntities())
                    {
                        #region Update Positions

                        positions.ForEach(item =>
                        {
                            var existingRecord = dbContext.UserPortlets.Where(u => u.AspNetUsersID == userId && u.PortletID == item.PortletID).FirstOrDefault();
                            if (existingRecord != null)
                            {
                                existingRecord.ColumnPosition = item.ColPosition;
                                existingRecord.RowPosition = item.RowPosition;
                            }
                        });

                        #endregion

                        #region Commit
                        dbContext.SaveChanges();
                        transaction.Complete();
                        #endregion
                    }

                }
            }
        }
    }
}
