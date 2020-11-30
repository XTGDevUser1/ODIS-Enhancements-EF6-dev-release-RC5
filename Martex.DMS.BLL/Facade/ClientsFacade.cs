using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using System.Transactions;
using Martex.DMS.Models;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public partial class ClientsFacade
    {

        /// <summary>
        /// Lists the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<SearchClients_Result> List(Guid userId, PageCriteria pc)
        {
            ClientRepository repository = new ClientRepository();
            return repository.Search(userId, pc);
        }

        /// <summary>
        /// Gets the specified client id.
        /// </summary>
        /// <param name="clientId">The client id.</param>
        /// <returns></returns>
        public Client Get(string clientId)
        {
            if (!string.IsNullOrEmpty(clientId))
            {
                ClientRepository repository = new ClientRepository();
                return repository.Get(int.Parse(clientId));
            }
            return null;
        }

        /// <summary>
        /// Gets the client by client name.
        /// </summary>
        /// <param name="clientName">Name of the client.</param>
        /// <returns></returns>
        public Client GetByClientName(string clientName)
        {
            if (!string.IsNullOrEmpty(clientName))
            {
                ClientRepository repository = new ClientRepository();
                return repository.Get(clientName);
            }
            return null;
        }

        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <param name="userName">Name of the user.</param>
        public void Add(ClientModel model, int[] clientIdList, string userName)
        {

            model.Client.CreateDate = DateTime.Now;
            model.Client.ModifyDate = DateTime.Now;
            model.Client.CreateBy = userName;
            model.Client.ModifyBy = userName;

            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    ClientRepository clientRepository = new ClientRepository();
                    clientRepository.Add(model.Client, clientIdList);
                    tran.Complete();
                }
                catch (Exception)
                {
                    throw;
                }
            }
        }


        public void UpdateAvatar(int entityID, string entity, string avatar, string userName)
        {
            ClientRepository clientRepository = new ClientRepository();

            clientRepository.UpdateAvatar(entityID, entity,avatar, userName);
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="clientIdList">The client id list.</param>
        /// <param name="userName">Name of the user.</param>
        public void Update(ClientModel model, int[] clientIdList, string userName)
        {

            model.Client.ModifyDate = DateTime.Now;
            model.Client.ModifyBy = userName;

            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    ClientRepository clientRepository = new ClientRepository();
                    model.Client.IsActive = model.isActive;
                    clientRepository.Update(model.Client, clientIdList);
                    tran.Complete();
                }
                catch (Exception)
                {
                    throw;
                }

            }

        }

        /// <summary>
        /// Deletes the specified client id.
        /// </summary>
        /// <param name="clientId">The client id.</param>
        public void Delete(string clientId)
        {
            ClientRepository repository = new ClientRepository();
            repository.Delete(int.Parse(clientId));
        }

        /// <summary>
        /// Gets the client batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ClientBatchList_Result> GetClientBatchList(PageCriteria pc)
        {
            ClientRepository repository = new ClientRepository();
            return repository.GetClientBatchList(pc);
        }

        public List<ClientBatchPaymentRunsList_Result> GetClientBatchPaymentRunsList(PageCriteria pc, int? batchID)
        {
            ClientRepository repository = new ClientRepository();
            return repository.GetClientBatchPaymentRunsList(pc, batchID);
        }

    }
}
