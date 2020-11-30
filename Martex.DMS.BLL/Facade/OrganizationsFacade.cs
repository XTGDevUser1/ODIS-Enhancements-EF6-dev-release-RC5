using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.Models;
using System.Transactions;


namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to manage Organizations
    /// </summary>
    public class OrganizationsFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(OrganizationsFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// Lists the specified user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<SearchOrganizations_Result> List(Guid userId, PageCriteria pc)
        {
            OrganizationRepository repository = new OrganizationRepository();
            return repository.Search(userId, pc);
        }

        /// <summary>
        /// Gets the specified organization id.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public Organization Get(string organizationId)
        {
            if (!string.IsNullOrEmpty(organizationId))
            {
                OrganizationRepository organizationRepository = new OrganizationRepository();
                return organizationRepository.Get(organizationId);
            }
            return null;
        }

        /// <summary>
        /// Gets the name of the organization by.
        /// </summary>
        /// <param name="organizationName">Name of the organization.</param>
        /// <returns></returns>
        public Organization GetOrganizationByName(string organizationName)
        {
            if (!string.IsNullOrEmpty(organizationName))
            {
                OrganizationRepository organizationRepository = new OrganizationRepository();
                return organizationRepository.GetOrganizationByName(organizationName);
            }
            return null;
        }

        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Add(OrganizationModel model, string userName)
        {

            model.Organization.CreateDate = DateTime.Now;
            model.Organization.ModifyDate = DateTime.Now;
            model.Organization.CreateBy = userName;
            model.Organization.ModifyBy = userName;
            model.Organization.IsActive = true;

            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    OrganizationRepository organizationRepository = new OrganizationRepository();
                    organizationRepository.Add(model.Organization, model.OrganizationRolesValues, model.OrganizationClientsValues);

                    // Process address and phone records
                    logger.Info("Processing addresses");
                    var addressFacade = new AddressFacade();
                    addressFacade.SaveAddresses(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.InsertedAddresses, AddressFacade.ADD);

                    logger.Info("Processing phone details");
                    var phoneFacade = new PhoneFacade();
                    phoneFacade.SavePhoneDetails(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.InsertedPhoneDetails, PhoneFacade.ADD);

                    tran.Complete();
                }
                catch (Exception)
                {
                    throw;
                }
            }
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Update(OrganizationModel model, string userName)
        {
            model.Organization.ModifyDate = DateTime.Now;
            model.Organization.ModifyBy = userName;
            
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    OrganizationRepository organizationRepository = new OrganizationRepository();
                    organizationRepository.Update(model.Organization, model.OrganizationRolesValues, model.OrganizationClientsValues);

                    // Process address and phone records
                    logger.Info("Processing addresses");
                    var addressFacade = new AddressFacade();
                    addressFacade.SaveAddresses(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.InsertedAddresses,AddressFacade.ADD);
                    addressFacade.SaveAddresses(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.UpdatedAddresses, AddressFacade.EDIT);
                    addressFacade.SaveAddresses(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.DeletedAddresses, AddressFacade.DELETE);

                    logger.Info("Processing phone details");
                    var phoneFacade = new PhoneFacade();
                    phoneFacade.SavePhoneDetails(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.InsertedPhoneDetails, PhoneFacade.ADD);
                    phoneFacade.SavePhoneDetails(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.UpdatedPhoneDetails, PhoneFacade.EDIT);
                    phoneFacade.SavePhoneDetails(model.Organization.ID, EntityNames.ORGANIZATION, userName, model.DeletedPhoneDetails, PhoneFacade.DELETE);

                    tran.Complete();
                }
                catch (Exception)
                {
                    throw;
                }
            }

        }

        /// <summary>
        /// Deletes the specified organization id.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <exception cref="DMSException">Cannot delete Organization because it is linked to other records.</exception>
        public void Delete(string organizationId)
        {
            OrganizationRepository organizationRepository = new OrganizationRepository();
            if (organizationRepository.IsOrganizationAsParentOrganization(int.Parse(organizationId)))
            {
                throw new DMSException("Cannot delete Organization because it is linked to other records.");
            }
            organizationRepository.Delete(int.Parse(organizationId));
        }

        /// <summary>
        /// Gets the roles.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public List<DropDownRoles> GetRoles(int? organizationId)
        {
            return ReferenceDataRepository.GetUserRoles(organizationId);
        }

        /// <summary>
        /// Gets the organization clients.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <returns></returns>
        public List<Client> GetOrganizationClients(int organizationId)
        {
            return ReferenceDataRepository.GetOrganizationClients(organizationId);
        }

        /// <summary>
        /// Gets the state province.
        /// </summary>
        /// <param name="countryId">The country id.</param>
        /// <returns></returns>
        public List<StateProvince> GetStateProvince(int countryId)
        {
            ReferenceDataRepository referanceDataRepository = new ReferenceDataRepository();
            return ReferenceDataRepository.GetStateProvinces(countryId);
        }

        /// <summary>
        /// Gets the state province.
        /// </summary>
        /// <param name="countryName">Name of the country.</param>
        /// <returns></returns>
        public List<StateProvince> GetStateProvince(string countryName)
        {
            ReferenceDataRepository referanceDataRepository = new ReferenceDataRepository();
            return ReferenceDataRepository.GetStateProvinces(countryName);
        }


        public List<Program> GetProgramonClient(int Clinet)
        {
            ReferenceDataRepository referanceDataRepository = new ReferenceDataRepository();
            return ReferenceDataRepository.GetProgram(Clinet);
        }


        #endregion
    }
}
