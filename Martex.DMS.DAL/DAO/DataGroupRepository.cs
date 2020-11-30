using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class DataGroupRepository
    {
        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        public List<DataGroup> GetAll()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.DataGroups.ToList<DataGroup>();
                return list;
            }
        }

        /// <summary>
        /// Adds the specified data group.
        /// </summary>
        /// <param name="dataGroup">The data group.</param>
        /// <exception cref="DMSException">
        /// User doesn't belong to any organization.
        /// or
        /// That DataGroup name already exists.
        /// </exception>
        public void Add(DataGroup dataGroup)
        {
            // Sanghi : To Do
            // In DG earlier we were not having the OrganizationID at the UI level.
            // Tht's why OrganizationID was getting retrieved based on the current user.
            // Now when we have OrganizationID is it necessary to check in the user table.
            // For time being i have added OrganizationID whihc is coming from the UI.
            using (DMSEntities dbContext = new DMSEntities())
            {
                var dataGroupObject = dbContext.DataGroups.Where(a => a.Name == dataGroup.Name).FirstOrDefault();
                var user = dbContext.aspnet_Users.Where(x => x.UserName == dataGroup.CreateBy).Include(a=>a.Users).FirstOrDefault();
                if (user != null)
                {
                    var userProfile = user.Users.FirstOrDefault();
                    if (userProfile == null)
                    {
                        throw new DMSException("User doesn't belong to any organization.");
                    }

                    dataGroup.OrganizationID = dataGroup.OrganizationID;
                }
                if (dataGroupObject != null)
                {
                    throw new DMSException("That DataGroup name already exists.");
                }
                dbContext.DataGroups.Add(dataGroup);
                dbContext.Entry(dataGroup).State = EntityState.Added;
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Updates the specified data group.
        /// </summary>
        /// <param name="dataGroup">The data group.</param>
        /// <param name="dataGroupProgramList">The data group program list.</param>
        /// <exception cref="DMSException">That DataGroup name already exists.</exception>
        public void Update(DataGroup dataGroup, int[] dataGroupProgramList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var dataGroupDuplicateObject = dbContext.DataGroups.Where(a => a.Name == dataGroup.Name && a.ID != dataGroup.ID).FirstOrDefault();
                if (dataGroupDuplicateObject != null)
                {
                    throw new DMSException("That DataGroup name already exists.");
                }
                var dataGroupObject = dbContext.DataGroups.Where(a => a.ID == dataGroup.ID).Include(d=>d.DataGroupPrograms).FirstOrDefault();
                dataGroupObject.OrganizationID = dataGroup.OrganizationID;
                dataGroupObject.Name = dataGroup.Name;
                dataGroupObject.Description = dataGroup.Description;
                dataGroupObject.ModifyBy = dataGroup.ModifyBy;
                dataGroupObject.ModifyDate = dataGroup.ModifyDate;
                List<int> updatedDataGroupProgramList = new List<int>();
                List<int> deletedDataGroupProgramList = new List<int>();
                updatedDataGroupProgramList = dataGroupProgramList.ToList();
                // Remove the selected programs which are already added with this data group
                dataGroupObject.DataGroupPrograms.ToList<DataGroupProgram>().ForEach(x =>
                {
                    if (dataGroupProgramList.Where(a => a == x.ProgramID).ToList().Count > 0)
                    {
                        updatedDataGroupProgramList.Remove(x.ProgramID);
                    }
                    else
                    {
                        // Add to list which datagroupprogram has to be deleted
                        deletedDataGroupProgramList.Add(x.ID);
                    }
                });
                // Delete the DataGroupProgram which have been removed
                dataGroupObject.DataGroupPrograms.ToList<DataGroupProgram>().ForEach(x =>
                {
                    if (deletedDataGroupProgramList.Where(a => a == x.ID).ToList().Count > 0)
                    {
                        dbContext.Entry(x).State = EntityState.Deleted;
                    }
                });
                // Add new DataGroupProgram items 
                foreach (int dataGroupProgramId in updatedDataGroupProgramList)
                {
                    dataGroupObject.DataGroupPrograms.Add(new DataGroupProgram() { ProgramID = dataGroupProgramId });
                }
                dbContext.Entry(dataGroupObject).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the specified data group id.
        /// </summary>
        /// <param name="dataGroupId">The data group id.</param>
        /// <exception cref="DMSException">Cannot delete DataGroup because it is linked to Users</exception>
        public void Delete(int dataGroupId)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                var dataGroup = dbContext.DataGroups.Where(a => a.ID == dataGroupId).FirstOrDefault();
                if (dataGroup != null)
                {
                    if (dbContext.UserDataGroups.Where(a => a.DataGroupID == dataGroupId).ToList().Count() > 0)
                    {
                        throw new DMSException("Cannot delete DataGroup because it is linked to Users");
                    }

                    var dataGroupProgs = dbContext.DataGroupPrograms.Where(x => x.DataGroupID == dataGroupId).ToList<DataGroupProgram>();

                    dataGroupProgs.ForEach(d =>
                    {
                        dbContext.Entry(d).State = EntityState.Deleted;
                    });

                    dbContext.Entry(dataGroup).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the specified data group id.
        /// </summary>
        /// <param name="dataGroupId">The data group id.</param>
        /// <returns></returns>
        public DataGroup Get(int dataGroupId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var dataGroup = dbContext.DataGroups.Where(a => a.ID == dataGroupId)
                                                    .Include(d=> d.DataGroupPrograms)
                                                    .First();
                return dataGroup;
            }
        }

        /// <summary>
        /// Searches the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<DataGroupList> Search(Guid userId, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetDataGroupsList(userId, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<DataGroupList>();
            }
        }
    }
}
