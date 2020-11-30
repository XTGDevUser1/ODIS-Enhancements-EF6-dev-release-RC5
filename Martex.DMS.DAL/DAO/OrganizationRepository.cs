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
    public class OrganizationRepository
    {
        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        public List<Organization> GetAll()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Organizations.ToList<Organization>();
                return list;
            }
        }
        /// <summary>
        /// Adds the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="roleIdList">The role id list.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <exception cref="DMSException">Organization name already exists</exception>
        public void Add(Organization entity, Guid[] roleIdList, int[] clientIdList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Organizations.Add(entity);
                if (roleIdList != null)
                {
                    foreach (Guid roleId in roleIdList)
                    {
                        entity.OrganizationRoles.Add(new OrganizationRole { RoleID = roleId });
                    }
                }
                if (clientIdList != null)
                {
                    foreach (int clientId in clientIdList)
                    {
                        entity.OrganizationClients.Add(new OrganizationClient { ClientID = clientId });
                    }
                }
                var organization = dbContext.Organizations.Where(x => x.Name == entity.Name).FirstOrDefault();
                if (organization != null)
                {
                    throw new DMSException("Organization name already exists");
                }
                dbContext.Entry(entity).State = EntityState.Added;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="roleIdList">The role id list.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <exception cref="DMSException">Organization name already exists</exception>
        public void Update(Organization entity, Guid[] roleIdList, int[] clientIdList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var duplicateOrganization = dbContext.Organizations.Where(x => x.Name == entity.Name && x.ID != entity.ID).FirstOrDefault();
                if (duplicateOrganization != null)
                {
                    throw new DMSException("Organization name already exists");
                }
                var organization = dbContext.Organizations.Include(x => x.OrganizationRoles).Include(x => x.OrganizationClients).Where(x => x.ID == entity.ID).FirstOrDefault();
                organization.Name = entity.Name;
                organization.ParentOrganizationID = entity.ParentOrganizationID;
                organization.Description = entity.Description;
                organization.ModifyDate = entity.ModifyDate;
                organization.ModifyBy = entity.ModifyBy;
                organization.ContactName = entity.ContactName;
                // Delete existing roles
                organization.OrganizationRoles.ToList<OrganizationRole>().ForEach(x =>
                {
                    dbContext.Entry(x).State = EntityState.Deleted;
                });
                
                // Add new roles
                if (roleIdList != null)
                {
                    foreach (Guid roleId in roleIdList)
                    {
                        organization.OrganizationRoles.Add(new OrganizationRole { RoleID = roleId });
                    }
                }
                // Delete existing Clients
                organization.OrganizationClients.ToList<OrganizationClient>().ForEach(x =>
                {
                    dbContext.Entry(x).State = EntityState.Deleted;
                });
                
                // Add new clients
                if (clientIdList != null)
                {
                    foreach (int clientId in clientIdList)
                    {
                        organization.OrganizationClients.Add(new OrganizationClient { ClientID = clientId });
                    }
                }
                dbContext.Entry(organization).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }
        /// <summary>
        /// Deletes the specified organization id.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <exception cref="DMSException">Cannot delete Organization because it is linked to other records.</exception>
        public void Delete(int organizationId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var organization = dbContext.Organizations.Where(a => a.ID == organizationId).First();
                if (organization != null)
                {

                    if (organization.OrganizationRoles.Count > 0 || organization.OrganizationClients.Count > 0)
                    {
                        throw new DMSException("Cannot delete Organization because it is linked to other records.");
                    }
                    dbContext.Entry(organization).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Organization Get<T1>(T1 id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                int organizationId = int.Parse(id.ToString());
                var organization = dbContext.Organizations.Include(x=> x.OrganizationClients).Include(x=>x.OrganizationRoles).Where(a => a.ID == organizationId).First();
                return organization;
            }
        }


        /// <summary>
        /// Gets the organization by name.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Organization GetOrganizationByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //int organizationId = int.Parse(id.ToString());
                var organization = dbContext.Organizations.Where(a => a.Name == name).First();
                return organization;
            }
        }
        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<Organization> GetAllFor<T1>(T1 id, DAL.Common.PageCriteria pageCriteria)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Searches the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<SearchOrganizations_Result> Search(Guid userId, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetOrganizations(userId, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<SearchOrganizations_Result>();
            }
        }
        /// <summary>
        /// Determines whether [is organization as parent organization] [the specified organization id].
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns>
        ///   <c>true</c> if [is organization as parent organization] [the specified organization id]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsOrganizationAsParentOrganization(int organizationId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Organizations.Where(a => a.ParentOrganizationID == organizationId).ToList();
                if (list != null && list.Count > 0)
                {
                    return true;
                }
            }
            return false;

        }

    }
}
