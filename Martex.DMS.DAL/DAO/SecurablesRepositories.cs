using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.Transactions;

namespace Martex.DMS.DAL.DAO
{
    public class SecurablesRepositories
    {
        /// <summary>
        /// Get Securables List
        /// </summary>
        /// <param name="pageCriteria"></param>
        /// <returns></returns>
        public List<SecurablesList_Result> GetSecurablesList(PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetSecurablesList(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection).ToList();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="securableID"></param>
        /// <returns></returns>
        public SecurableModel GetSecurbalePermissions(int securableID)
        {
            SecurableModel model = new SecurableModel();
            using (DMSEntities dbContext = new DMSEntities())
            {
                model.Securable = dbContext.Securables.Where(u => u.ID == securableID).FirstOrDefault();

                model.Items = dbContext.GetSecurbalePermissions(securableID).Select(u => new SecurableModelItems()
                {
                    RoleName = u.RoleName,
                    AccessTypeID = u.AccessTypeID,
                    AccessTypeName = u.AccessTypeName,
                    RoleID = u.RoleId
                }).ToList();
            }

            model.Items.ForEach(x =>
            {
                if (!x.AccessTypeID.HasValue)
                {
                    x.AccessTypeName = "None";
                }
            });
            return model;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        public void Save(SecurableModel model)
        {
            using (TransactionScope transaction = new TransactionScope())
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var existingItem = dbContext.Securables.Where(u => u.ID == model.Securable.ID).FirstOrDefault();
                    if (existingItem != null)
                    {
                        List<AccessControlList> existingAccessList = dbContext.AccessControlLists.Where(u => u.SecurableID == model.Securable.ID).ToList();
                        if (existingAccessList != null && existingAccessList.Count > 0)
                        {
                            existingAccessList.ForEach(x => 
                            {
                                dbContext.AccessControlLists.Remove(x);
                            });
                        }
                        model.Items.ForEach(x => 
                        {
                            dbContext.AccessControlLists.Add(new AccessControlList() 
                            {
                                SecurableID = existingItem.ID,
                                RoleID = x.RoleID.GetValueOrDefault(),
                                AccessTypeID = x.AccessTypeID.GetValueOrDefault()
                            });
                        });
                        
                        dbContext.SaveChanges();
                    }
                    else
                    {
                        throw new Exception(string.Format("Unable to retrieve Securable ID {0}", model.Securable.ID));
                    }          
                }
                transaction.Complete();
            }
        }
    }
}
