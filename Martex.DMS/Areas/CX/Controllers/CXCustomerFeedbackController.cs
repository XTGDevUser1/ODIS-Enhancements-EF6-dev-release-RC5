using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
//using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.BLL.SMTPSettings;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Common;
using System.Web.Script.Serialization;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.QA.Controllers
{
    /// <summary>
    /// Customer Feedback Controller
    /// </summary>
    [ValidateInput(false)]
    public partial class CXCustomerFeedbackController : BaseController
    {

        #region Private Members
        private CustomerFeedbackFacade facade = new CustomerFeedbackFacade();
        #endregion

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CX_CUSTOMER_FEEDBACK)]
        public ActionResult Index()
        {
            CustomerFeedbackSearchCriteria model = new CustomerFeedbackSearchCriteria();
            model = model.GetModelForSearchCriteria();
            logger.Info("Inside the Index() method in Customer Feedback Controller");
            return View(model);
        }

        /// <summary>
        /// Survey the search.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CXSearch([DataSourceRequest] DataSourceRequest request, CustomerFeedbackSearchCriteria model)
        {
            logger.Info("Inside CXCustomerFeedback Controller. Attempt to get all Customer Feedback depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = null;
            string sortOrder = null;
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterSearchCritera();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            List<dms_CustomerFeedback_list_Result> list = new List<dms_CustomerFeedback_list_Result>();
            if (filter.Count > 0)
            {
                list = facade.GetCustomerfeedbackdata(pageCriteria);
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int? totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows.GetValueOrDefault()
            };

            return Json(result);
        }


        /// <summary>
        /// Loads the search criteria.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CustomerFeedbackSearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackIDFilterTypes, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackClient, true)]
        //[ReferenceDataFilter(StaticData.CustomerFeedbackProgram, true)]
        [ReferenceDataFilter(StaticData.NextAction, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackSearchCriteriaValueFilterType, true)]

        [HttpPost]
        public ActionResult _SearchCriteria(CustomerFeedbackSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() model in CXCustomerFeedbackController with Model:{0}", model);
            //ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            ViewData[StaticData.CustomerFeedbackIDFilterTypes.ToString()] = ReferenceDataRepository.GetCustomerFeedbackIDFilterTypes(CallFrom.FEEDBACK).ToSelectListItem<DropDownEntityForString>(x => x.Value.ToString(), y => y.Text.ToString(), true);
            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                CustomerFeedbackSearchCriteria dbModel = model.GetView(model.FilterToLoadID.Value) as CustomerFeedbackSearchCriteria;
                if (dbModel != null)
                {
                    //    if (dbModel.Statuses.Count != 0)
                    //    {
                    //        ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetCustomerFeedbackStatus().ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                    //    }
                    return View(dbModel);
                }
            }
            logger.Info("Returns the View");
            return View(tempHoldModel);



        }

        /// <summary>
        /// Loads the selected criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(CustomerFeedbackSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in VendorHomeController with Model:{0}", model);
            logger.Info("Returns the View");
            return View(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Gets the vendor details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="tabIndex">Index of the tab.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        //[ReferenceDataFilter(StaticData.CustomerFeedbackStatus, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackSource, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackPriority, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackRequestBy, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackAssignedTo, true)]
        //[ReferenceDataFilter(StaticData.CustomerFeedbackNextaction, true)]
        //[ReferenceDataFilter(StaticData.AllActiveUsers, true)]
        [ReferenceDataFilter(StaticData.CustomerFeedbackNextaction, true)]
        [ReferenceDataFilter(StaticData.FinishUsers, true)]
        //[ReferenceDataFilter(StaticData.CXUsers, true)]
        [ReferenceDataFilter(StaticData.MemberShipMembers, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, true)]
        public ActionResult _Details(int? customerFeedbackId)
        {
            logger.InfoFormat("Inside the _Details() method in CXCustomerFeedback Controller with Record ID:{0}", customerFeedbackId);
            CustomerFeedbackModel model = new CustomerFeedbackModel();
            ViewData[StaticData.WorkedByUsers.ToString()] = facade.GetUsersByAppConfigSettings(AppConfigConstants.APPCONFIG_FEEDBACK_ROLE_SETTING_NAME).ToSelectListItem<dms_Users_By_Appconfig_Role_Setting_Get_Result>(x => x.ID.ToString(), y => y.FirstName + " " + y.LastName, true);
            var customerFeedbackStatusList = ReferenceDataRepository.GetCustomerFeedbackStatus_List().ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name.ToString(), true);

            if (customerFeedbackId != null)
            {
                var customerFeedback = facade.GetCustomerFeedbackById(customerFeedbackId);
                model.CustomerFeedback = customerFeedback;
                model.FeedbackType = facade.GetCustomerFeedbackTypeForFeedback(customerFeedbackId);

                // Check if the record is locked by some other user and attempt to lock it otherwise.
                var userProfile = GetProfile();
                if (customerFeedback.AssignedToUserID != null && customerFeedback.AssignedToUserID != userProfile.ID)
                {
                    logger.InfoFormat("CX Record {0} is locked by User {1}", customerFeedback.ID, customerFeedback.AssignedToUserID);
                    UserRepository userRepository = new UserRepository();
                    var lockedByUser = userRepository.GetUserById(customerFeedback.AssignedToUserID.Value);
                    model.RecordLockedBy = string.Format("{0} {1}", lockedByUser.FirstName, lockedByUser.LastName);
                }
                else
                {
                    logger.InfoFormat("Record {0} is not locked, attempting to lock with User ID ", customerFeedback.ID, userProfile.ID);
                    model.RecordLockedBy = null;
                    var customerFeedbackRepository = new CustomerFeedbackRepository();
                    customerFeedbackRepository.LockCustomerFeedback(customerFeedback.ID, userProfile.ID);
                }

                //Getting Customerfeedback status by id
                if(customerFeedback.CustomerFeedbackStatusID.HasValue)
                {
                    var customerFeedbackStatus = ReferenceDataRepository.GetCustomerFeedbackStatusById(customerFeedback.CustomerFeedbackStatusID.Value);
                    if (customerFeedbackStatus == null)
                    {
                        throw new DMSException(string.Format("CustomerFeedbackStatus with id - {0} is not found in the system", customerFeedback.CustomerFeedbackStatusID.Value));
                    }

                    model.CustomerFeedbackStatusName = customerFeedbackStatus.Name;
                                        
                    if (model.CustomerFeedbackStatusName != CustomerFeedbackStatusNames.PENDING)
                    {                        
                        customerFeedbackStatusList = ReferenceDataRepository.GetCustomerFeedbackStatus_List().Where(x => x.Name != CustomerFeedbackStatusNames.PENDING).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name.ToString(), true);
                    }
                    
                }     

                QueueRepository repository = new QueueRepository();
                var srDetails = repository.GetServiceRequest(customerFeedback.ServiceRequestID.GetValueOrDefault()).FirstOrDefault();
                if (srDetails != null)
                {
                    model.ClientName = srDetails.Client;
                    model.ProgramName = srDetails.ProgramName;
                }
                
            }
            else
            {
                model.CustomerFeedback = new CustomerFeedback();
            }

            ViewData[StaticData.CustomerFeedbackStatus.ToString()] = customerFeedbackStatusList;

            logger.InfoFormat("Returns the View with Model:{0}", model);
            return View(model);
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult Add(CustomerFeedback model)
        {
            OperationResult result = new OperationResult();
            if (model.ServiceRequestID == null)
            {
                throw new DMSException("Invalid service request information");
            }
            var customerFeedback = facade.CreateCustomerFeedback(model.ServiceRequestID.GetValueOrDefault(), model.PurchaseOrderNumber, CustomerFeedbackStatusNames.OPEN, Request.RawUrl, Session.SessionID, LoggedInUserName);
            result.Data = customerFeedback.ID;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult _ValidateByPONumber(string numberValue)
        {
            OperationResult result = new OperationResult();
            bool isSRExists = false;

            var repository = new CustomerFeedbackRepository();
            var searchResults = repository.GetCustomerFeedbackBy(NumberTypeConstants.PURCHASE_ORDER, numberValue);
            if (searchResults.Count == 0)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.Data = new { Message = string.Format("Purchase Order {0} number not found. Please try again.", numberValue) };
            }
            else
            {
                int? serviceRequestId = searchResults[0].ServiceRequestID.HasValue ? searchResults[0].ServiceRequestID : null;
                isSRExists = facade.IsCustomerFeedbackExistsForSR(serviceRequestId);

                var tempResult = new
                {
                    Result = searchResults,
                    IsSRExists = isSRExists
                };

                result.Data = tempResult;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [HttpGet]
        public ActionResult _ValidateBySRNumber(string searchTerm)
        {
            OperationResult result = new OperationResult();

            var emptyItem = new GetCustomerFeedbackHeaderBySROrPO_Result()
            {

            };
            var searchResults = new List<GetCustomerFeedbackHeaderBySROrPO_Result>();

            if (string.IsNullOrWhiteSpace(searchTerm))
            {
                emptyItem.MembershipNumber = "Please enter something to search on";
                searchResults.Add(emptyItem);
            }
            else
            {
                var repository = new CustomerFeedbackRepository();
                searchResults = repository.GetCustomerFeedbackBy(NumberTypeConstants.SERVICE_REQUEST, searchTerm);
                if (searchResults.Count == 0)
                {
                    emptyItem.MembershipNumber = "No Service reqeusts found.Please adjust the search criteria and try again";
                    searchResults.Clear();
                    searchResults.Add(emptyItem);
                }
                else
                {
                    int? serviceRequestId = searchResults[0].ServiceRequestID.HasValue ? searchResults[0].ServiceRequestID : null;
                    searchResults[0].IsSRExists = facade.IsCustomerFeedbackExistsForSR(serviceRequestId);
                }
            }

            ComboGridModel gridModel = new ComboGridModel()
            {
                Count = searchResults.Count,
                records = searchResults.Count,
                total = searchResults.Count,
                rows = searchResults.ToArray<GetCustomerFeedbackHeaderBySROrPO_Result>()
            };

            return Json(gridModel, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the priority for source.
        /// </summary>
        /// <param name="SourceId"></param>
        /// <returns></returns>
        [DMSAuthorize]
        public int GetProrityOnSource(int SourceId)
        {
            return facade.GetPrioritiesBySource(SourceId);
        }

        /// <summary>
        /// Unlock for Owner
        /// </summary>
        /// <param name="recordID"></param>
        /// <returns></returns>
        public ActionResult UnlockRecord(int recordID)
        {
            logger.InfoFormat("Attempt to unlock CustomerFeedbackRecord {0}", recordID);
            OperationResult result = new OperationResult();
            facade.UnlockIfOwner(recordID, GetProfile().ID.Value);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        // Unlock by CXMgr  
        public ActionResult UnlockLockedCutomerfedback(int CustomerFeedbackID)
        {

            logger.InfoFormat("Attempt to unlock locked CustomerFeedbackRecord {0}", CustomerFeedbackID);
            OperationResult result = new OperationResult();
            facade.UnlockByCXMgr(CustomerFeedbackID, GetProfile().ID.Value);
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        public ActionResult OpenLockedCustomerfeedback(int CustomerFeedbackID)
        {
            logger.InfoFormat("Attempt to open locked CustomerFeedbackRecord {0}", CustomerFeedbackID);
            OperationResult result = new OperationResult();
            facade.OpenbyCXMgr(CustomerFeedbackID, GetProfile().ID.Value);
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public ActionResult UpdateCustomerFeedbackStatusToOpen(int customerFeedBackId)
        {
            OperationResult result = new OperationResult();
            var customerFeedbackStatus = ReferenceDataRepository.GetCustomerFeedbackStatusByName(CustomerFeedbackStatusNames.OPEN);
            if (customerFeedbackStatus == null)
            {
                throw new DMSException(string.Format("CustomerFeedbackStatus with name - {0} is not found in the system", CustomerFeedbackStatusNames.OPEN));
            }

            facade.UpdateCustomerFeedbackStatusToOpen(customerFeedBackId, customerFeedbackStatus.ID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

    }

}

