using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using ClientPortal.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;

namespace ClientPortal.Areas.Common.Controllers
{
    public class ReferenceDataController : BaseController
    {
        #region Private Members
        const string CONTROL_FOR = "controlFor";
        #endregion
      
        #region Public Methods
        /// <summary>
        /// Get List of Programs for Organization
        /// </summary>
        /// <param name="organizationId"></param>
        /// <param name="controlFor"></param>
        /// <returns></returns>
        public ActionResult ProgramsForOrganization(string organizationId, string controlFor)
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetDataGroupPrograms((Guid)GetLoggedInUser().ProviderUserKey,organizationId).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
            ViewData[CONTROL_FOR] = controlFor;
            return PartialView("_Dropdown_Multi_Select", list);
        }
        /// <summary>
        /// Get List of Roles for the Organization
        /// </summary>
        /// <param name="organizationId"></param>
        /// <param name="controlFor"></param>
        /// <returns></returns>
        public ActionResult RolesForOrganization(string organizationId, string controlFor)
        {
            OrganizationsFacade facade = new OrganizationsFacade();
            List<DropDownRoles> list;
            if (!string.IsNullOrEmpty(organizationId) && organizationId != "Select")
            {
                list = facade.GetRoles(int.Parse(organizationId));
            }
            else
            {
                list = facade.GetRoles(null);
            }

            ViewData[CONTROL_FOR] = controlFor;
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<DropDownRoles>(x => x.RoleName, y => y.RoleName, false);
            return PartialView("_Dropdown_Multi_Select", selectList);

        }
        /// <summary>
        /// Get List of Roles
        /// </summary>
        /// <param name="organizationId"></param>
        /// <param name="controlFor"></param>
        /// <returns></returns>
        public ActionResult RolesForOrganizationGettingValueAsID(string organizationId, string controlFor)
        {
            OrganizationsFacade facade = new OrganizationsFacade();
            List<DropDownRoles> list;
            if (!string.IsNullOrEmpty(organizationId) && organizationId!= "Select")
            {
                list = facade.GetRoles(int.Parse(organizationId));
            }
            else
            {
                list = facade.GetRoles(null);
            }

            ViewData[CONTROL_FOR] = controlFor;
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<DropDownRoles>(x => x.RoleID.ToString(), y => y.RoleName, false);
            return PartialView("_Dropdown_Multi_Select", selectList);

        }
        /// <summary>
        /// Get List of Clients
        /// </summary>
        /// <param name="organizationId"></param>
        /// <param name="controlFor"></param>
        /// <param name="userId"></param>
        /// <returns></returns>
        public ActionResult ClientForOrganization(string organizationId, string controlFor, Guid userId)
        {
            OrganizationsFacade facade = new OrganizationsFacade();
            ViewData[CONTROL_FOR] = controlFor;
            List<Client> list;
            if (!string.IsNullOrEmpty(organizationId) && organizationId != "Select")
            {
                list = facade.GetOrganizationClients(int.Parse(organizationId));
                IEnumerable<SelectListItem> selectList = list.ToSelectListItem<Client>(x => x.ID.ToString(), y => y.Name, false);
                return PartialView("_Dropdown_Multi_Select", selectList);
            }
            else
            {
                return PartialView("_Dropdown_Multi_Select", ReferenceDataRepository.GetClients(userId).ToSelectListItem<Clients_Result>(x => x.ClientID.ToString(), y => y.ClientName, false));
            }
        }
        /// <summary>
        /// Get List of Data Groups
        /// </summary>
        /// <param name="organizationId"></param>
        /// <param name="controlFor"></param>
        /// <returns></returns>
        public ActionResult DataGroupsForOrganization(string organizationId, string controlFor)
        {
            UsersFacade facade = new UsersFacade();
            List<DropDownDataGroup> list;
            list = facade.GetDropDownDataGroup(int.Parse(organizationId));
            ViewData[CONTROL_FOR] = controlFor;
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<DropDownDataGroup>(x => x.ID.ToString(), y => y.Name, false);
            return PartialView("_Dropdown_Multi_Select", selectList);
        }
        /// <summary>
        /// Get List of State
        /// </summary>
        /// <param name="countryId"></param>
        /// <returns></returns>
        public ActionResult StateProvinceRelatedToCountry(string countryId)
        {
            int iCountryId = 0;
            int.TryParse(countryId, out iCountryId);
            OrganizationsFacade facade = new OrganizationsFacade();
            List<StateProvince> list = null;
            if (iCountryId > 0)
            {
                list = facade.GetStateProvince(iCountryId);
            }
            else
            {
                list = facade.GetStateProvince(countryId);
            }
            //IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }
        /// <summary>
        /// Get List of Payment Reason
        /// </summary>
        /// <param name="transactionType"></param>
        /// <returns></returns>
        public ActionResult GetPaymentReason(string transactionType)
        {
            int iTransactionType = 0;
            int.TryParse(transactionType, out iTransactionType);
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetPaymentReasons(iTransactionType).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            return new JsonResult { Data = new SelectList(list, "Value", "Text") };
        }
        #endregion
    }
}
