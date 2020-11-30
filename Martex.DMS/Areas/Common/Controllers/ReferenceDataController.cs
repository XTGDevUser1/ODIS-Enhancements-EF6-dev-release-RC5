using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Common;
using Martex.DMS.Models;
using System.Web.Security;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.Areas.Application.Models;
using log4net;
using Martex.DMS.DAL.DAO;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Common.Controllers
{
    /// <summary>
    /// Reference Data Controller
    /// </summary>
    public class ReferenceDataController : BaseController
    {
        #region Private Members
        const string CONTROL_FOR = "controlFor";
        #endregion

        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberFacade));
        #endregion
        #region Public Methods

        /// <summary>
        /// Method user for Phone Control
        /// </summary>
        /// <returns></returns>
        public ActionResult GetCountryExceptPR()
        {
            List<Country> list = ReferenceDataRepository.GetCountryTelephoneCode(false);
            logger.InfoFormat("ReferenceDataController - GetCountryExceptPR(), Countries : {0}", JsonConvert.SerializeObject(new
            {
                Count = list != null ? list.Count : 0
            }));
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.ISOCode.Trim()), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the type of the notification recipient.
        /// </summary>
        /// <returns></returns>
        public ActionResult GetNotificationRecipientType()
        {
            List<NotificationRecipientType> list = ReferenceDataRepository.GetNotificationRecipientType();
            logger.InfoFormat("ReferenceDataController - GetNotificationRecipientType() : {0}", JsonConvert.SerializeObject(new
            {
                Count = list != null ? list.Count : 0,
                result = list.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true)
            }));
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description.Trim(), true), JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Gets the user manager.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public ActionResult GetUserManager(string userName)
        {
            OperationResult result = new OperationResult();
            string managerName = string.Empty;
            if (!string.IsNullOrEmpty(userName))
            {
                MembershipUser user = System.Web.Security.Membership.GetUser(userName);
                if (user != null)
                {
                    UserRepository repository = new UserRepository();
                    User teamManager = repository.GetUserManager((Guid)user.ProviderUserKey);
                    if (teamManager != null)
                    {
                        managerName = string.Join(" ", teamManager.FirstName, teamManager.LastName);
                    }
                }
            }
            result.Data = new { ManagerName = managerName };
            logger.InfoFormat("ReferenceDataController - GetUserManager() : {0}", JsonConvert.SerializeObject(new
            {
                userName = userName,
                ManagerName = managerName
            }));
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="applicationName"></param>
        /// <returns></returns>
        public ActionResult GetUsers(string applicationName)
        {
            List<aspnet_Users> list = ReferenceDataRepository.GetUsers(applicationName);
            logger.InfoFormat("ReferenceDataController - GetUsers() : {0}", JsonConvert.SerializeObject(new
            {
                applicationName = applicationName,
                result = list.ToSelectListItem(x => x.UserName, y => y.UserName, true)
            }));
            return Json(list.ToSelectListItem(x => x.UserName, y => y.UserName, true), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="concernTypeID"></param>
        /// <returns></returns>
        public ActionResult GetConcerns(int? concernTypeID)
        {
            List<Concern> list = ReferenceDataRepository.GetConcern(concernTypeID.GetValueOrDefault());
            logger.InfoFormat("ReferenceDataController - GetConcerns() : {0}", JsonConvert.SerializeObject(new
            {
                concernTypeID = concernTypeID,
                result = list.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true)
            }));
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the billing definition invoice.
        /// </summary>
        /// <param name="clientID">The client ID.</param>
        /// <returns></returns>
        public ActionResult GetBillingDefinitionInvoice(int? clientID)
        {

            List<BillingDefinitionInvoice> list = new List<BillingDefinitionInvoice>();
            if (clientID.HasValue)
            {
                list = ReferenceDataRepository.GetBillingDefinitionInvoice(clientID);
            }
            logger.InfoFormat("ReferenceDataController - GetBillingDefinitionInvoice() : {0}", JsonConvert.SerializeObject(new
            {
                clientID = clientID,
                result = list.ToSelectListItem(x => x.ID.ToString(), y => y.Description.Trim(), true)
            }));
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description.Trim(), true), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the billing events.
        /// </summary>
        /// <param name="lineID">The line ID.</param>
        /// <returns></returns>
        public ActionResult GetBillingEvents(string lineID)
        {
            List<ClientBillableEventProcessingCascadeBillingEvent_Result> list = new List<ClientBillableEventProcessingCascadeBillingEvent_Result>();
            list = ReferenceDataRepository.GetBillingEvents(lineID);
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description.Trim(), true), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the state province.
        /// </summary>
        /// <param name="countryID">The country ID.</param>
        /// <returns></returns>
        public ActionResult GetStateProvince(int? countryID)
        {
            List<StateProvince> list = ReferenceDataRepository.GetStateProvinces(countryID.GetValueOrDefault());
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim())).ToList();
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            return Json(listItem, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="categoryID"></param>
        /// <param name="eventTypeID"></param>
        /// <returns></returns>
        public ActionResult GetEvents(int? categoryID, int? eventTypeID)
        {
            List<Event> list = ReferenceDataRepository.GetEvents();
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.ID.ToString(), y => y.Description).ToList();

                if (categoryID.HasValue && eventTypeID.HasValue)
                {
                    listItem = list.Where(u => u.EventCategoryID == categoryID.GetValueOrDefault() && u.EventTypeID == eventTypeID.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Description).ToList();
                }
                else if (categoryID.HasValue)
                {
                    listItem = list.Where(u => u.EventCategoryID == categoryID.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Description).ToList();
                }
                else if (eventTypeID.HasValue)
                {
                    listItem = list.Where(u => u.EventTypeID == eventTypeID.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Description).ToList();
                }
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            return Json(listItem, JsonRequestBehavior.AllowGet);
        }

        public ActionResult GetMemberByMembershipNumber(string membershipNumber)
        {
            List<DropDownEntity> list = ReferenceDataRepository.GetMembersByMembershipNumber(membershipNumber);
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.ID.ToString(), y => y.Name).ToList();
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            return Json(listItem, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the state province with ID.
        /// </summary>
        /// <param name="countryID">The country ID.</param>
        /// <returns></returns>
        public ActionResult GetStateProvinceWithID(int? countryID)
        {
            List<StateProvince> list = ReferenceDataRepository.GetStateProvinces(countryID.GetValueOrDefault());
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim())).ToList();
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            return Json(listItem, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get List of Programs for Organization
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <param name="controlFor">The control for.</param>
        /// <returns></returns>
        public ActionResult ProgramsForOrganization(string organizationId, string controlFor)
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetDataGroupPrograms((Guid)GetLoggedInUser().ProviderUserKey, organizationId).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
            ViewData[CONTROL_FOR] = controlFor;
            return PartialView("_Dropdown_Multi_Select", list);
        }

        /// <summary>
        /// Get List of Roles for the Organization
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <param name="controlFor">The control for.</param>
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
        /// <param name="organizationId">The organization id.</param>
        /// <param name="controlFor">The control for.</param>
        /// <returns></returns>
        public ActionResult RolesForOrganizationGettingValueAsID(string organizationId, string controlFor)
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
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<DropDownRoles>(x => x.RoleID.ToString(), y => y.RoleName, false);
            return PartialView("_Dropdown_Multi_Select", selectList);

        }

        /// <summary>
        /// Get List of Clients for Organizations
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <param name="controlFor">The control for.</param>
        /// <param name="userId">The user id.</param>
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
        /// Get List of Data Groups for Organizations.
        /// </summary>
        /// <param name="organizationId">The organization id.</param>
        /// <param name="controlFor">The control for.</param>
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
        /// <param name="countryId">The country id.</param>
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
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }



        public ActionResult ProgramToClient(int? Client)
        {
            List<Program> list = ReferenceDataRepository.GetProgram(Client.GetValueOrDefault());
            //List<SelectListItem> listItem = null;
            //if (list != null)
            //{
            //    listItem = list.ToSelectListItem(x => x.ID.ToString(), y =>  y.Name.Trim()).ToList();
            //}
            //if (listItem == null)
            //{
            //    listItem = new List<SelectListItem>();
            //}
            //listItem.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            //return Json(listItem, JsonRequestBehavior.AllowGet);
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<Program>(x => x.ID.ToString(), y => y.Name, true);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }


        //public ActionResult ProgramToClient(int Client)
        //{
        //    int iClientId = 0;
        //    int.TryParse(Client, out iClientId);
        //    OrganizationsFacade facade = new OrganizationsFacade();
        //    List<Program> list = null;
        //    if (iClientId > 0)
        //    {
        //        list = facade.GetProgramonClient(iClientId);
        //    }
        //    else
        //    {
        //        list = facade.GetProgramonClient(Client);
        //    }
        //    IEnumerable<SelectListItem> selectList = list.ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
        //    return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        //}

        /// <summary>
        /// Get the Products related to product category.
        /// </summary>
        /// <param name="productCategoryId">The product category identifier.</param>
        /// <returns></returns>
        public ActionResult ProductsRelatedToProductCategory(int? productCategoryId)
        {
            ReferenceDataRepository repository = new ReferenceDataRepository();
            List<ProductForProductCategory_Result> list = repository.GetProductsRelatedToProductCategory(productCategoryId);
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<ProductForProductCategory_Result>(x => x.ID.ToString(), y => string.Format("{0}", y.Name.Trim()), true);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }

        public ActionResult GetRateSchedulesRelatedToContract(string contractID)
        {
            int iContractID = 0;
            int.TryParse(contractID, out iContractID);
            ReferenceDataRepository repo = new ReferenceDataRepository();
            List<ContractRateSchedule> list = null;
            if (iContractID > 0)
            {
                list = repo.GetRateSchedulesRelatedToContract(iContractID);
            }
            else
            {
                list = repo.GetRateSchedulesRelatedToContract(iContractID);
            }
            IEnumerable<SelectListItem> selectList = list.ToSelectListItem<ContractRateSchedule>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID.ToString(), y.StartDate.ToString().Trim()), false);
            return new JsonResult { Data = new SelectList(selectList, "Value", "Text") };
        }

        /// <summary>
        /// Get List of Payment Reason
        /// </summary>
        /// <param name="transactionType">Type of the transaction.</param>
        /// <returns></returns>
        public ActionResult GetPaymentReason(string transactionType)
        {
            int iTransactionType = 0;
            int.TryParse(transactionType, out iTransactionType);
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetPaymentReasons(iTransactionType).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            return new JsonResult { Data = new SelectList(list, "Value", "Text") };
        }

        /// <summary>
        /// Gets the vendor source.
        /// </summary>
        /// <returns></returns>
        public ActionResult GetVendorSource()
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVendorSourceTypes().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            //return new JsonResult { Data = new SelectList(list, "Value", "Text") };
            var Data = new SelectList(list, "Value", "Text");
            return Json(Data, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="clientID"></param>
        /// <returns></returns>
        public ActionResult ProgramMaintenanceParentProgram(int? clientID)
        {
            List<Program> list = ReferenceDataRepository.GetProgramByClientOrderByID(clientID.GetValueOrDefault());
            List<SelectListItem> items = new List<SelectListItem>();
            items.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            list.ForEach(x =>
            {
                items.Add(new SelectListItem()
                {
                    Text = x.IsGroup ? x.Name + " (Group)" : x.Name,
                    Value = x.ID.ToString()
                });
            });
            var Data = new SelectList(items, "Value", "Text");
            return Json(Data, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Gets the default uom for rate type.
        /// </summary>
        /// <param name="rateTypeID">The rate type identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult GetDefaultUOMForRateType(int? id)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (id != null)
            {
                var uom = ReferenceDataRepository.GetRateTypeByID(id.Value);
                if (uom != null)
                {
                    result.Data = uom.UnitOfMeasure;
                }
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult LogEventForEnterAndLeaveTabs(int tabId, bool isEntering)
        {
            OperationResult result = new OperationResult();
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            var srAgentTimeRepository = new SRAgentTimeRepository();
            int? srAgentTimeID = null;
            var srAgentTime = DMSCallContext.SRAgentTime;
            if (srAgentTime != null)
            {
                srAgentTimeID = srAgentTime.ID;
            }
            string source = string.Empty;
            string eventName = ReferenceDataRepository.GetEventName(tabId, isEntering);
            if (string.IsNullOrEmpty(eventName))
            {
                throw new DMSException(string.Format("No Event Name is registered for  {1} tab with id {0}", tabId.ToString(), isEntering ? "Entering" : "Leaving"));
            }
            if (tabId > 0)
            {
                var eventLogID = eventLoggerFacade.LogEvent(source, eventName, eventName, LoggedInUserName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
                if (srAgentTimeID != null)
                {
                    var timeElapsed = (int)(DateTime.Now - srAgentTime.BeginDate.Value).TotalSeconds;
                    srAgentTimeRepository.UpdateEvent(srAgentTimeID.Value, eventLogID, timeElapsed);
                }
            }
            else if (tabId == 0)
            {
                if (!isEntering)
                {
                    string enterStartTabEventName = ReferenceDataRepository.GetEventName(tabId, true);
                    if (string.IsNullOrEmpty(enterStartTabEventName))
                    {
                        throw new DMSException(string.Format("No Event Name is registered for Entering tab with id {0}", tabId.ToString()));
                    }
                    string leaveStartTabEventName = ReferenceDataRepository.GetEventName(tabId, false);
                    if (string.IsNullOrEmpty(leaveStartTabEventName))
                    {
                        throw new DMSException(string.Format("No Event Name is registered for Leaving tab with id {0}", tabId.ToString()));
                    }
                    IRepository<Event> eventRepository = new EventRepository();
                    Event theEvent = eventRepository.Get<string>(enterStartTabEventName);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name " + enterStartTabEventName);
                    }

                    EventLog eventLog = new EventLog();
                    eventLog.Source = source;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = Session.SessionID;
                    eventLog.Description = enterStartTabEventName;
                    if (DMSCallContext.StartingPoint == StringConstants.START)
                    {
                        InboundCall _callDetails = new InboundCallRepository().GetInboundCallById(DMSCallContext.InboundCallID);
                        if (_callDetails == null)
                        {
                            throw new DMSException("No Inbound Call Details found with ID :  " + DMSCallContext.InboundCallID.ToString());
                        }
                        eventLog.CreateDate = _callDetails.CreateDate;
                    }
                    else
                    {
                        eventLog.CreateDate = DateTime.Now;
                    }
                    eventLog.CreateBy = LoggedInUserName;

                    EventLogRepository eventLogRepository = new EventLogRepository();
                    eventLogRepository.Add(eventLog, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);

                    var eventLogID = eventLoggerFacade.LogEvent(source, leaveStartTabEventName, leaveStartTabEventName, LoggedInUserName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
                    if (srAgentTimeID != null)
                    {
                        var timeElapsed = (int)(DateTime.Now - srAgentTime.BeginDate.Value).TotalSeconds;
                        srAgentTimeRepository.UpdateEvent(srAgentTimeID.Value, eventLogID, timeElapsed);
                    }

                }
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion
    }
}
