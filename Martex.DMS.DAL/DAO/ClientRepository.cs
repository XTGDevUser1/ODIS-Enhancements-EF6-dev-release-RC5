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
    public partial class ClientRepository
    {

        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        public List<Client> GetAll()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.Clients.ToList<Client>();
                return list;
            }
        }

        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns></returns>
        public Client Get(int Id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Clients.Where(a => a.ID == Id)
                    .Include(x=>x.OrganizationClients)
                    .SingleOrDefault();
            }
        }

        /// <summary>
        /// Gets client by specified name.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Client Get(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Clients.Where(a => a.Name == name)
                    .Include(x => x.OrganizationClients)
                    .SingleOrDefault();
            }
        }

        /// <summary>
        /// Adds the specified client.
        /// </summary>
        /// <param name="client">The client.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <exception cref="DMSException">That Client name already exists.</exception>
        public void Add(Client client, int[] clientIdList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var clientObject = dbContext.Clients.Where(a => a.Name == client.Name).FirstOrDefault();
                if (clientObject != null)
                {
                    throw new DMSException("That Client name already exists.");
                }
                dbContext.Clients.Add(client);
                dbContext.SaveChanges();

                if (clientIdList != null)
                {
                    foreach (int clientId in clientIdList)
                    {
                        //client.OrganizationClients.Add(new OrganizationClient { OrganizationID = clientId });
                        OrganizationClient oc = new OrganizationClient();
                        oc.OrganizationID = clientId;
                        oc.ClientID = client.ID;
                        dbContext.OrganizationClients.Add(oc);
                        dbContext.SaveChanges();
                    }
                }

            }
        }

        public void UpdateAvatar(int entityID, string entity, string clientAvatar, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (entity == "Client")
                {
                    var client = dbContext.Clients.Where(x => x.ID == entityID).FirstOrDefault();
                    if (client != null)
                    {
                        client.Avatar = clientAvatar;
                        client.ModifyBy = userName;
                        client.ModifyDate = DateTime.Now;
                        dbContext.Entry(client).State = EntityState.Modified;
                        dbContext.SaveChanges();
                    }
                }
                else if(entity=="ClientRep")
                {
                    var clientRep = dbContext.ClientReps.Where(x => x.ID == entityID).FirstOrDefault();
                    if (clientRep != null)
                    {
                        clientRep.Avatar = clientAvatar;
                        clientRep.ModifyBy = userName;
                        clientRep.ModifyDate = DateTime.Now;
                        dbContext.Entry(clientRep).State = EntityState.Modified;
                        dbContext.SaveChanges();
                    }
                }
            }
        }

        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <exception cref="DMSException">That Client name is already exists.</exception>
        public void Update(Client entity, int[] clientIdList)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var clientDuplicateObject = dbContext.Clients.Where(a => a.Name == entity.Name && a.ID != entity.ID).FirstOrDefault();
                if (clientDuplicateObject != null)
                {
                    throw new DMSException("That Client name is already exists.");
                }
                var client = dbContext.Clients.Where(x => x.ID == entity.ID).Include(a=>a.OrganizationClients).FirstOrDefault();
                client.Name = entity.Name;
                client.Description = entity.Description;
                client.AccountingSystemAddressCode = entity.AccountingSystemAddressCode;
                client.AccountingSystemCustomerNumber = entity.AccountingSystemCustomerNumber;
                //TFS: 694 - AccountingSystemDivisionCode
                client.AccountingSystemDivisionCode = entity.AccountingSystemDivisionCode;
                client.IsActive = entity.IsActive;
                client.ModifyDate = entity.ModifyDate;
                client.ModifyBy = entity.ModifyBy;

                client.ClientRepID = entity.ClientRepID;
                client.ClientTypeID = entity.ClientTypeID;
                client.MainContactFirstName = entity.MainContactFirstName;
                client.MainContactLastName = entity.MainContactLastName;
                client.MainContactPhone = entity.MainContactPhone;
                client.MainContactEmail = entity.MainContactEmail;
                client.Website = entity.Website;

                List<int> updatedClientOrganizationsList = new List<int>();
                List<int> deletedClientOrganizationsList = new List<int>();
                updatedClientOrganizationsList = clientIdList.ToList();
                // Remove the selected programs which are already added with this data group
                client.OrganizationClients.ToList<OrganizationClient>().ForEach(x =>
                {
                    if (clientIdList.Where(a => a == x.OrganizationID).ToList().Count > 0)
                    {
                        updatedClientOrganizationsList.Remove(x.OrganizationID);
                    }
                    else
                    {
                        // Add to list which datagroupprogram has to be deleted
                        deletedClientOrganizationsList.Add(x.ID);
                    }
                });
                // Delete the ClientOrganizations which have been removed
                client.OrganizationClients.ToList<OrganizationClient>().ForEach(x =>
                {
                    if (deletedClientOrganizationsList.Where(a => a == x.ID).ToList().Count > 0)
                    {
                        dbContext.Entry(x).State = EntityState.Deleted;
                    }
                });
                // Add new ClientOrganizations items 
                foreach (int organizationId in updatedClientOrganizationsList)
                {
                    client.OrganizationClients.Add(new OrganizationClient() { OrganizationID = organizationId });
                }
                dbContext.Entry(client).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Searches the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<SearchClients_Result> Search(Guid userId, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientsList(userId, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<SearchClients_Result>();
            }
        }

        /// <summary>
        /// Deletes the specified client id.
        /// </summary>
        /// <param name="clientId">The client id.</param>
        /// <exception cref="DMSException">Cannot delete Client because it is linked to other records.</exception>
        public void Delete(int clientId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var client = dbContext.Clients.Where(a => a.ID == clientId).Include(x=>x.OrganizationClients).FirstOrDefault();
                if (client != null)
                {
                    var clientProgram = dbContext.Programs.Where(a => a.ClientID == clientId).FirstOrDefault();
                    if ((client.OrganizationClients != null && client.OrganizationClients.Count() > 0) || clientProgram != null)
                    {
                        throw new DMSException("Cannot delete Client because it is linked to other records.");
                    }
                    if (client != null)
                    {

                    }
                    dbContext.Entry(client).State = EntityState.Deleted;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the client batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClientBatchList_Result> GetClientBatchList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientBatchList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ClientBatchList_Result>();
            }
        }

        public List<ClientBatchPaymentRunsList_Result> GetClientBatchPaymentRunsList(PageCriteria pc, int? batchID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetClientBatchPaymentRunsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, batchID).ToList<ClientBatchPaymentRunsList_Result>();
            }
        }

        public Client GetClientByProgram(int programID)
        {
            var client = new Client();
            using (DMSEntities dbContext = new DMSEntities())
            {
                client = (from cl in dbContext.Clients
                          join pr in dbContext.Programs on cl.ID equals pr.ClientID
                          where pr.ID == programID
                          select cl
                          ).FirstOrDefault();
            }
            return client;
        }
    }
}
