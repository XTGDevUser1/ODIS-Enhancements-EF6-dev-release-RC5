using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using ClientPortal.Models;
using Martex.DMS.DAO;
using ClientPortal.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using System.Text;
using ClientPortal.Areas.Application.Models;
using System.Xml;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;

namespace ClientPortal.Areas.Application.Controllers
{
    public class MemberController : BaseController
    {

        #region Protected Properties
        protected int MemberShipID
        {
            get
            {
                return DMSCallContext.MembershipID;
            }
        }

        #endregion

        #region Private Methods

        private string GetWhereClauseXMLForAssociateList(int memberShipID)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");
                writer.WriteAttributeString("MembershipIDOperator", "2");
                writer.WriteAttributeString("MembershipIDValue", memberShipID.ToString());
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
        }
        private string GetWhereClauseXML(MemberSearchCriteria searchCriteria)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                // Append operator and values
                if (!string.IsNullOrEmpty(searchCriteria.MemberNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "2");
                    writer.WriteAttributeString("MemberNumberValue", searchCriteria.MemberNumber);
                }
                if (!string.IsNullOrEmpty(searchCriteria.LastName))
                {
                    writer.WriteAttributeString("LastNameOperator", "4");
                    writer.WriteAttributeString("LastNameValue", searchCriteria.LastName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.FirstName))
                {
                    writer.WriteAttributeString("FirstNameOperator", "4");
                    writer.WriteAttributeString("FirstNameValue", searchCriteria.FirstName);
                }
                if (searchCriteria.MemberProgramID > 0)
                {
                    string programName = ReferenceDataRepository.GetProgramByID(searchCriteria.MemberProgramID.Value).Code;
                    writer.WriteAttributeString("ProgramOperator", "2");
                    writer.WriteAttributeString("ProgramValue", programName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.Phone))
                {
                    writer.WriteAttributeString("PhoneNumberOperator", "6");
                    writer.WriteAttributeString("PhoneNumberValue", searchCriteria.Phone);
                }
                if (!string.IsNullOrEmpty(searchCriteria.VIN))
                {
                    writer.WriteAttributeString("VINOperator", "6");
                    writer.WriteAttributeString("VINValue", searchCriteria.VIN);
                }
                if (!string.IsNullOrEmpty(searchCriteria.State))
                {
                    writer.WriteAttributeString("StateOperator", "2");
                    writer.WriteAttributeString("StateValue", searchCriteria.State);
                }
                if (!string.IsNullOrEmpty(searchCriteria.ZipCode))
                {
                    writer.WriteAttributeString("ZipCodeOperator", "4");
                    writer.WriteAttributeString("ZipCodeValue", searchCriteria.ZipCode);
                }
                if (searchCriteria.MemberID > 0)
                {
                    writer.WriteAttributeString("MemberIDOperator", "2");
                    writer.WriteAttributeString("MemberIDValue", searchCriteria.MemberID.ToString());
                }

                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Display Member Details
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Suffix, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Prefix, false)]
        [ReferenceDataFilter(StaticData.Province, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        // Where id = Program ID
        public ActionResult Index(int? childProgramID)
        {
            //TODO
            int programID = DMSCallContext.ProgramID;
            ViewData[StaticData.ProgramsForMember.ToString()] = ReferenceDataRepository.GetProgramForMember(programID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);
            var phoneTypesList = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = phoneTypesList;
            ViewData["SelectedProgramID"] = childProgramID ?? programID;
            var model = new MemberModel() { CaseID = DMSCallContext.CaseID, ProgramID = programID, PhoneNumber = DMSCallContext.CallbackNumber, PhoneType = DMSCallContext.ContactPhoneTypeID };
            model.ClientReferenceControlData = MemberRepository.GetClientReferenceControlData(programID, "RegisterMember");
            model.Country = 1; // Default TO US
            if ((model.PhoneType ?? 0) == 0)
            {
                var homeType = phoneTypesList.Where(x => x.Text == "Home").FirstOrDefault();
                if (homeType != null)
                {
                    model.PhoneType = int.Parse(homeType.Value);
                }
            }
            return PartialView("_Member", model);
        }

        /// <summary>
        /// Get the list of childern programs.
        /// </summary>
        /// <param name="programID"></param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetChildrenPrograms(int programID)
        {
            var list = ReferenceDataRepository.GetProgramForMember(programID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);
            return Json(list);
        }
        /// <summary>
        /// Get the Client Reference Data
        /// </summary>
        /// <param name="programID"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult ClientReferenceControlData(string programID)
        {
            MemberModel model = new MemberModel();
            model.ClientReferenceControlData = MemberRepository.GetClientReferenceControlData(int.Parse(programID), "RegisterMember");
            return PartialView("_ClientReferenceControlData", model);
        }
        /// <summary>
        /// Save Member Details
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Save(MemberModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Saving member {0}, {1}.", model.FirstName, model.LastName);
            MemberFacade facade = new MemberFacade();
            facade.Save(model, GetLoggedInUser().UserName, HttpContext.Session.SessionID);

            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            result.Data = model.MemberID;
            return Json(result);
        }
        /// <summary>
        /// Get the Blank Address
        /// </summary>
        /// <param name="recordId"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _SelectAddress(string recordId)
        {
            return Json(new List<AddressEntity>());
        }
        /// <summary>
        /// Get State List
        /// </summary>
        /// <param name="Country"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetComboBoxState(int Country)
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetStateProvinces(Country).ToSelectListItem(id => id.ID.ToString(), code => code.Name);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get Member ID used in telerik Grid
        /// </summary>
        /// <param name="memberID"></param>
        /// <param name="membershipID"></param>
        /// <returns></returns>
        public ActionResult GetMemberID(int memberID, int membershipID)
        {
            Member memberDetails = new MemberFacade().GetMemberDetailsbyID(memberID);
            if (memberDetails == null)
            {
                throw new DMSException("Unable to retrieve the details for the member");
            }

            DMSCallContext.MemberProgramID = memberDetails.ProgramID.Value;
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside GetMemberID() of Memebr. Call by the grid with the userId {0} - {1}, try to returns the Json object", memberID, membershipID);
            DMSCallContext.MembershipID = membershipID;
            DMSCallContext.MemberID = memberID;
            return Json(new { MemberID = memberID, MembershipID = membershipID }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// _SearchServiceRequestHistrory Method for Service Request History Grid
        /// </summary>
        /// <param name="command"></param>
        /// <returns></returns>
        /// 
        [NoCache]
        [DMSAuthorize(Roles = "SysAdmin,ClientAdmin")]
        public ActionResult _SearchServiceRequestHistrory([DataSourceRequest] DataSourceRequest request, int memberId)
        {
            logger.Info("Inside List() of MemeberController. Attempt to get all Service Request History depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = string.Empty;
            string sortOrder = string.Empty;

            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                SortColumn = sortColumn,
                SortDirection = sortOrder,
                WhereClause = string.Empty
            };

            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            MemberFacade facade = new MemberFacade();
            List<RecentServiceRequest> list = facade.GetServiceRequestHistory(memberId);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            //if (list.Count > 0)
            //{
            //    totalRows = list[0].TotalRows.Value;
            //}
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        ///// <summary>
        ///// Display List of Service Request History
        ///// </summary>
        ///// <param name="command"></param>
        ///// <param name="memberId"></param>
        ///// <returns></returns>
        //[DMSAuthorize]
        //[GridAction(EnableCustomBinding = true)]
        //[NoCache]
        //public ActionResult _SearchServiceRequestHistrory(GridCommand command, int memberId)
        //{
        //    string sortColumn = string.Empty;
        //    string sortOrder = string.Empty;
        //    if (command.SortDescriptors.Count > 0)
        //    {
        //        sortColumn = command.SortDescriptors[0].Member;
        //        sortOrder = (command.SortDescriptors[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
        //    }
        //    PageCriteria pageCriteria = new PageCriteria()
        //    {
        //        SortColumn = sortColumn,
        //        SortDirection = sortOrder,
        //        WhereClause = string.Empty
        //    };
        //    MemberFacade facade = new MemberFacade();
        //    List<RecentServiceRequest> list = facade.GetServiceRequestHistory(memberId);
        //    return View(new GridModel() { Data = list });
        //}

        /// <summary>
        /// Display Member Details
        /// </summary>
        /// <param name="memberID"></param>
        /// <param name="membershipID"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberDetails(int memberID, int membershipID)
        {
            logger.InfoFormat("Loading member {0} details", memberID);

            // Set the session variables
            DMSCallContext.MemberID = memberID;
            DMSCallContext.MembershipID = membershipID;

            MemberFacade facade = new MemberFacade();
            MemberSearchDetails model = new MemberSearchDetails();
            model.Vehicle = facade.GetVehicleInformation(memberID, membershipID);
            model.ServiceRequest = facade.GetServiceRequestHistory(membershipID);
            model.MemberInformation = facade.GetMemberInformation(memberID);

            var memberDetail = model.MemberInformation.Where(x => x.MemberID == memberID).FirstOrDefault();
            if (memberDetail != null)
            {
                DMSCallContext.MemberProgramID = memberDetail.ProgramID.Value;
            }

            // CR : 1294 : Enable / disable payment tab.
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(DMSCallContext.MemberProgramID, "Application", "Rule");
            bool allowPayment = false;
            var item = result.Where(x => (x.Name.Equals("AllowPaymentProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (item != null)
            {
                allowPayment = true;
            }
            DMSCallContext.AllowPaymentProcessing = allowPayment;
            logger.InfoFormat("Program allows payment processing : {0}", allowPayment);
            return PartialView("_SearchDetailsPopUp", model);
        }
        /// <summary>
        /// Perform Search on member.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.Province, false)]
        [NoCache]
        public ActionResult Search()
        {
            logger.Info("Inside Search() of Member Controller");
            ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetProgramForMember(DMSCallContext.ProgramID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);//ReferenceDataRepository.GetDataGroupPrograms((Guid)GetLoggedInUser().ProviderUserKey, string.Empty).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
            //List<SearchMember_Result> list = new List<SearchMember_Result>();//facade.SearchMember(pageCriteria);
            return PartialView("_SearchMember");
        }
        /// <summary>
        /// Perform Search on Member
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchCriteria"></param>
        /// <returns></returns>
        [DMSAuthorize]        
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, MemberSearchCriteria searchCriteria)
        {

            List<SearchMember_Result> list = new List<SearchMember_Result>();
            int totalRows = 0;

            if (string.IsNullOrEmpty(searchCriteria.FirstName) &&
               string.IsNullOrEmpty(searchCriteria.LastName) &&
               searchCriteria.MemberID == 0 &&
               string.IsNullOrEmpty(searchCriteria.MemberNumber) &&
                string.IsNullOrEmpty(searchCriteria.Phone) &&
                string.IsNullOrEmpty(searchCriteria.State) &&
                string.IsNullOrEmpty(searchCriteria.VIN) &&
                string.IsNullOrEmpty(searchCriteria.ZipCode)
                )
            {
                logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
                return Json(new DataSourceResult() { Data = list, Total = totalRows });
            }

            if (!string.IsNullOrEmpty(searchCriteria.FirstName) ||
                !string.IsNullOrEmpty(searchCriteria.LastName) ||
                searchCriteria.MemberID > 0 ||
                !string.IsNullOrEmpty(searchCriteria.MemberNumber) ||
                !string.IsNullOrEmpty(searchCriteria.Phone) ||
                !searchCriteria.MemberProgramID.HasValue ||
                !string.IsNullOrEmpty(searchCriteria.State) ||
                !string.IsNullOrEmpty(searchCriteria.VIN) ||
                !string.IsNullOrEmpty(searchCriteria.ZipCode) ||
                (searchCriteria.ProgramID > 0)
                )
            {
                logger.Info("Inside SearchList() of Member Controller");
                GridUtil gridUtil = new GridUtil();
                string sortColumn = "Name";
                string sortOrder = "ASC";
                if (request.Sorts.Count > 0)
                {
                    sortColumn = request.Sorts[0].Member;
                    sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
                }
                PageCriteria pageCriteria = new PageCriteria()
                {
                    StartInd = request.PageSize * (request.Page - 1) + 1,
                    EndInd = request.PageSize * request.Page,
                    PageSize = request.PageSize,
                    SortColumn = sortColumn,
                    SortDirection = sortOrder,
                    WhereClause = GetWhereClauseXML(searchCriteria)
                };
                MemberFacade facade = new MemberFacade();
                if (string.IsNullOrEmpty(pageCriteria.WhereClause))
                {
                    pageCriteria.WhereClause = null;
                }
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId();
                list = facade.SearchMember(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, searchCriteria.ProgramID, HttpContext.Session.SessionID);


                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
            }

            logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
            if (!searchCriteria.MemberFoundFromMobile)
            {
                //// Clear the mobile record in session
                DMSCallContext.MobileCallForServiceRecord = null;
            }            
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }


        /// <summary>
        /// Retrieve Member Details
        /// </summary>
        /// <returns></returns>
        /// 
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_MEMBER)]
        [ReferenceDataFilter(StaticData.Country, false)]
        // [ReferenceDataFilter(StaticData.Province, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult MemberDetails()
        {
            logger.InfoFormat("Loading member details for membership ID : {0}", DMSCallContext.MemberID);
            int memberID = DMSCallContext.MemberID;
            int membershipID = DMSCallContext.MembershipID;

            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            MemberFacade facade = new MemberFacade();
            MemberDetailsModel memberModel = new MemberDetailsModel();
            memberModel.MembershipContactInformation = facade.GetMembershipContactInformation(memberID);
            DMSCallContext.MemberEmail = memberModel.MembershipContactInformation.EMail;
            memberModel.MembershipInformation = facade.GetMembershipInformation(memberID);

            // Retrieve the member status and hold it in Session.
            DMSCallContext.MemberStatus = memberModel.MembershipInformation.MemberStatus;

            PageCriteria pageCriteriaForAssociate = new PageCriteria()
            {
                WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
            };

            PageCriteria pageCriteriaForServicerequestHistroy = new PageCriteria()
            {
                WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID),
                SortColumn = "CreateDate",
                SortDirection = "DESC",
                PageSize = 10,
                StartInd = 1,
                EndInd = 10
            };

            #region For Member Name Update
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(DMSCallContext.ProgramID, "ProgramInfo", "Rule");
            bool allowUpdate = false;
            if (result != null)
            {
                result.ForEach(x =>
                {
                    if (x.Name == "AllowMemberUpdate" && x.Value.Equals("yes", StringComparison.OrdinalIgnoreCase))
                    {
                        allowUpdate = true;
                    }
                });
            }
            memberModel.IsMemberNameEdit = allowUpdate;

            result = repository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
            bool defaultContactName = false;
            if (result != null)
            {
                var item = result.Where(x => x.Name.Equals("DefaultContactName") && "yes".Equals(x.Value, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (item != null)
                {
                    defaultContactName = true;
                }
            }

            ViewData["DefaultContactName"] = defaultContactName;

            #endregion


            memberModel.MemberAssociateList = facade.GetAssociateListForMember(pageCriteriaForAssociate);
            List<MemberServiceRequestHistory_Result> list = facade.GetMemberServiceRequestHistory(pageCriteriaForServicerequestHistroy);
            List<MemberServiceRequestHistory_Result> Filterlist = list.Where(u => u.ServiceRequestNumber != DMSCallContext.ServiceRequestID).ToList();
            memberModel.ServiceRequestHistory = Filterlist;
            if (memberModel.MembershipContactInformation != null)
            {
                ViewData[ClientPortal.ActionFilters.StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(memberModel.MembershipContactInformation.CountryID.HasValue ? memberModel.MembershipContactInformation.CountryID.Value : 1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, false);
            }
            else
            {
                ViewData[ClientPortal.ActionFilters.StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, false);
            }
            return PartialView("_MemberDetails", memberModel);
        }


        /// <summary>
        /// Save Member Details
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult SaveMemberDetails(MembershipContactInformation model)
        {
            OperationResult result = new OperationResult();
            MemberFacade facade = new MemberFacade();
            model.MemberID = DMSCallContext.MemberID;
            model.MemberShipID = DMSCallContext.MembershipID;

            facade.SaveMemberContactInformation(model, GetLoggedInUser().UserName, Request.RawUrl, DMSCallContext.ServiceRequestID, DMSCallContext.CaseID, Session.SessionID);

            // Update the DMSCallContext - Callback numbers
            DMSCallContext.StartCallData.ContactPhoneNumber = model.CallbackNumber.PhoneNumber;
            DMSCallContext.StartCallData.ContactPhoneTypeID = model.CallbackNumber.PhoneTypeID;
            DMSCallContext.ContactFirstName = model.FirstName;
            DMSCallContext.ContactLastName = model.LastName;

            DMSCallContext.StartCallData.ContactAltPhoneNumber = model.AlternateCallbackNumber.PhoneNumber;
            DMSCallContext.StartCallData.ContactAltPhoneTypeID = model.AlternateCallbackNumber.PhoneTypeID;

            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// ListResult Method for Search Request History Grid
        /// </summary>
        /// <param name="command"></param>
        /// <returns></returns>
        /// 
        [NoCache]
        [DMSAuthorize(Roles = "SysAdmin,ClientAdmin")]
        public ActionResult ListResult([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of MemeberController. Attempt to get all Members depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "UserName";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            //PageCriteria pageCriteria = new PageCriteria()
            //{
            //    StartInd = 1,
            //    EndInd = 10,
            //    PageSize = 10,
            //    SortColumn = sortColumn,
            //    SortDirection = sortOrder,
            //    WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
            //};
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            MemberFacade facade = new MemberFacade();
            List<MemberServiceRequestHistory_Result> list = facade.GetMemberServiceRequestHistory(pageCriteria);
            List<MemberServiceRequestHistory_Result> Filterlist = list.Where(u => u.ServiceRequestNumber != DMSCallContext.ServiceRequestID).ToList();
            int totalRows = 0;
            if (Filterlist.Count > 0)
            {
                totalRows = Filterlist[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        ///// <summary>
        ///// Perform search on Service Request History
        ///// </summary>
        ///// <param name="command"></param>
        ///// <returns></returns>
        //[DMSAuthorize]
        //[GridAction(EnableCustomBinding = true)]
        //[NoCache]
        //public ActionResult SearchMemberServiceRequestHistroy(GridCommand command)
        //{
        //    int totalRows = 0;
        //    string sortColumn = "CreateDate";
        //    string sortOrder = "DESC";
        //    if (command.SortDescriptors.Count > 0)
        //    {
        //        sortColumn = command.SortDescriptors[0].Member;
        //        sortOrder = (command.SortDescriptors[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
        //    }
        //    PageCriteria pageCriteria = new PageCriteria()
        //    {
        //        StartInd = 1,
        //        EndInd = 10,
        //        PageSize = 10,
        //        SortColumn = sortColumn,
        //        SortDirection = sortOrder,
        //        WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
        //    };
        //    MemberFacade facade = new MemberFacade();
        //    List<MemberServiceRequestHistory_Result> list = facade.GetMemberServiceRequestHistory(pageCriteria);
        //    if (list.Count > 0)
        //    {
        //        totalRows = list[0].TotalRows.Value;
        //    }
        //    return View(new GridModel() { Data = list, Total = totalRows });
        //}

        /// <summary>
        /// List Method for Memebers List Grid
        /// </summary>
        /// <param name="command"></param>
        /// <returns></returns>
        /// 
        [NoCache]
        [DMSAuthorize(Roles = "SysAdmin,ClientAdmin")]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of MemeberController. Attempt to get all Memebers depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Memeber List";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                SortColumn = sortColumn,
                SortDirection = sortOrder,
                WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            MemberFacade facade = new MemberFacade();
            List<MemberAssociateList_Result> list = facade.GetAssociateListForMember(pageCriteria);
            
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            //return View(new GridModel() { Data = list });
            return Json(result);
        }

        ///// <summary>
        ///// Get List of associates
        ///// </summary>
        ///// <param name="command"></param>
        ///// <returns></returns>
        //[DMSAuthorize]
        //[GridAction(EnableCustomBinding = true)]
        //[NoCache]
        //public ActionResult SearchAssociateList(GridCommand command)
        //{
        //    string sortColumn = string.Empty;
        //    string sortOrder = string.Empty;
        //    if (command.SortDescriptors.Count > 0)
        //    {
        //        sortColumn = command.SortDescriptors[0].Member;
        //        sortOrder = (command.SortDescriptors[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
        //    }
        //    PageCriteria pageCriteria = new PageCriteria()
        //    {
        //        SortColumn = sortColumn,
        //        SortDirection = sortOrder,
        //        WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
        //    };
        //    MemberFacade facade = new MemberFacade();
        //    List<MemberAssociateList_Result> list = facade.GetAssociateListForMember(pageCriteria);
        //    //return View(new GridModel() { Data = list });

        //    return Json(list);
        //}


        /// <summary>
        /// Get Service Request ID
        /// </summary>
        /// <param name="serviceRequestID"></param>
        /// <returns></returns>
        public ActionResult GetServiceRequestId(string serviceRequestID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside GetServiceRequestId() of UserController. Call by the grid with the serviceRequestID {0}, try to returns the Jeson object", serviceRequestID);
            return Json(new { serviceRequestID = serviceRequestID }, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// Retrieve Home Address
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetHomeAddress()
        {
            AddressRepository addressRepository = new AddressRepository();

            AddressEntity addressEntity = addressRepository.GetAddresses(DMSCallContext.MemberID, "Member", "Home").FirstOrDefault();



            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            if (addressEntity == null)
            {
                result.Data = null;
            }
            else
            {
                result.Data = string.Join(",", addressEntity.Line1 == null ? string.Empty : addressEntity.Line1,
                                               addressEntity.City == null ? string.Empty : addressEntity.City,
                                               addressEntity.StateProvince1 == null ? string.Empty : addressEntity.StateProvince1.Name,
                                               addressEntity.PostalCode == null ? string.Empty : addressEntity.PostalCode);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

    }
}
