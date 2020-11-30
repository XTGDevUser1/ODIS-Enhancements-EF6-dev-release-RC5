using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Models;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.Areas.Application.Models;
using System.Xml;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    ///
    /// </summary>
    public class MemberController : BaseController
    {

        #region Protected Properties
        /// <summary>
        /// Gets the member ship ID.
        /// </summary>
        /// <value>
        /// The member ship ID.
        /// </value>
        protected int MemberShipID
        {
            get
            {
                return DMSCallContext.MembershipID;
            }
        }

        #endregion

        #region Private Methods

        /// <summary>
        /// Gets the where clause XML for associate list.
        /// </summary>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Gets the where clause XML.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
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
        /// Gets the program dynamic fields.
        /// </summary>
        /// <param name="screenName">Name of the screen.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult GetMemberRegisterProgramDynamicFields(int programID)
        {
            string screenName = "RegisterMember";
            logger.InfoFormat("RequestController - GetProgramDynamicFields() - screenName : {0}, programID : {1}", screenName, programID);
            List<DynamicFields> list = new ProgramMaintenanceFacade().GetProgramDynamicFields(screenName, programID);
            return PartialView("_MemberRegisterProgramDynamicFields", list);
        }


        /// <summary>
        /// Display Member Details
        /// </summary>
        /// <param name="childProgramID">The child program ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.Suffix, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Prefix, false)]
        [ReferenceDataFilter(StaticData.Province, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult Index(int? childProgramID)
        {
            //TODO
            logger.InfoFormat("MemeberController - Index(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                childProgramID = childProgramID
            }));
            //logger.InfoFormat("MemberController - Index() - childProgramID : {0}", childProgramID);
            int programID = DMSCallContext.ProgramID;
            ViewData[StaticData.ProgramsForMember.ToString()] = ReferenceDataRepository.GetProgramForMember(programID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);
            var phoneTypesList = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = phoneTypesList;
            ViewData["SelectedProgramID"] = childProgramID.HasValue ? childProgramID.Value.ToString() : string.Empty; // ?? programID; // KB: Don't consider the parent program ID as it won't be there in the list at all.
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
        /// Get the list of children programs.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetChildrenPrograms(int programID)
        {
            logger.InfoFormat("MemberController - _GetChildrenPrograms() - programID : {0}", programID);
            var list = ReferenceDataRepository.GetProgramForMember(programID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);
            //Lakshmi - Hagerty Integration
            bool isHagertyProgram = DMSCallContext.IsAHagertyParentProgram;
            logger.InfoFormat("MemberController - _GetChildrenPrograms() - isHagertyProgram : {0}", isHagertyProgram);
            this.Session["IsHagertyProgram"] = isHagertyProgram.ToString();
            //end
            return Json(list);
        }

        /// <summary>
        /// Get the Client Reference Data
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult ClientReferenceControlData(string programID)
        {
            logger.InfoFormat("MemeberController - ClientReferenceControlData(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                programID = programID
            }));
            MemberModel model = new MemberModel();
            model.ClientReferenceControlData = MemberRepository.GetClientReferenceControlData(int.Parse(programID), "RegisterMember");
            return PartialView("_ClientReferenceControlData", model);
        }

        private string BlankIfNullOrEmpty(string s)
        {
            if (string.IsNullOrEmpty(s))
            {
                return string.Empty;
            }
            return s;
        }

        /// <summary>
        /// Save Member Details
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Save(MemberModel model)
        {

            logger.InfoFormat("MemeberController - Save(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                MemberModel = model
            }));
            OperationResult result = new OperationResult();
            logger.InfoFormat("Saving member {0}, {1}.", model.FirstName, model.LastName);
            MemberFacade facade = new MemberFacade();
            facade.Save(model, GetLoggedInUser().UserName, HttpContext.Session.SessionID);

            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            // TFS : 1392
            //result.Data = model.MemberID;
            result.Data = new { MemberID = model.MemberID, MembershipID = model.MembershipID };
            //END TFS : 1392

            #region Code not in use but might be considered in future
            /* Code to validate the fields on the server side.
            //TFS:182 - Validate fields based on programconfiguration.
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var programConfig = repository.GetProgramInfo(model.ProgramID, "RegisterMember", "Validation");

            List<string> fieldsFailedValidation = ValidateMemberFields(model, programConfig);

            if (fieldsFailedValidation.Count > 0)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.Data = fieldsFailedValidation;
            }
            else
            {
                logger.InfoFormat("Saving member {0}, {1}.", model.FirstName, model.LastName);
                MemberFacade facade = new MemberFacade();
                facade.Save(model, GetLoggedInUser().UserName, HttpContext.Session.SessionID);

                result.OperationType = "Success";
                result.Status = OperationStatus.SUCCESS;
                result.Data = model.MemberID;
            }
             * */
            #endregion
            logger.InfoFormat("Saved member successfully {0}, {1} ID is : {2}.", model.FirstName, model.LastName, model.MemberID);
            return Json(result);
        }

        /// <summary>
        /// Gets the fields for validation.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult GetFieldsForValidation(int? programID)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var programConfig = repository.GetProgramInfo(programID, "RegisterMember", "Validation");

            result.Data = programConfig;

            return Json(result, JsonRequestBehavior.AllowGet);

        }

        private List<string> ValidateMemberFields(MemberModel model, List<ProgramInformation_Result> programConfig)
        {
            // Validate fields based on the programConfiguration.
            List<string> fieldsFailedValidation = new List<string>();
            /*
             *  RequireAddress1
                RequireAddress2
                RequireAddress3
                RequireCity
                RequireCountry
                RequireEffectiveDate
                RequireEmail
                RequireExpirationDate
                RequireFirstName
                RequireLastName
                RequireMiddleName
                RequirePhone
                RequirePrefix
                RequireProgram
                RequireState
                RequireSuffix
                RequireZip
             */

            if (IsFieldRequired("RequirePrefix", programConfig) && model.Prefix == null)
            {
                fieldsFailedValidation.Add("Prefix");
            }
            if (IsFieldRequired("RequireFirstName", programConfig) && string.IsNullOrEmpty(model.FirstName))
            {
                fieldsFailedValidation.Add("First Name");
            }
            if (IsFieldRequired("RequireMiddleName", programConfig) && string.IsNullOrEmpty(model.MiddleName))
            {
                fieldsFailedValidation.Add("Middle Name");
            }
            if (IsFieldRequired("RequireLastName", programConfig) && string.IsNullOrEmpty(model.LastName))
            {
                fieldsFailedValidation.Add("Last Name");
            }
            if (IsFieldRequired("RequireSuffix", programConfig) && model.Suffix == null)
            {
                fieldsFailedValidation.Add("Suffix");
            }
            if (IsFieldRequired("RequirePhone", programConfig) && string.IsNullOrEmpty(model.PhoneNumber))
            {
                fieldsFailedValidation.Add("Phone");
            }
            if (IsFieldRequired("RequireAddress1", programConfig) && string.IsNullOrEmpty(model.AddressLine1))
            {
                fieldsFailedValidation.Add("Address Line1");
            }

            if (IsFieldRequired("RequireAddress2", programConfig) && string.IsNullOrEmpty(model.AddressLine2))
            {
                fieldsFailedValidation.Add("Address Line2");
            }

            if (IsFieldRequired("RequireAddress3", programConfig) && string.IsNullOrEmpty(model.AddressLine3))
            {
                fieldsFailedValidation.Add("Address Line3");
            }

            if (IsFieldRequired("RequireCity", programConfig) && string.IsNullOrEmpty(model.City))
            {
                fieldsFailedValidation.Add("City");
            }
            if (IsFieldRequired("RequireCountry", programConfig) && model.Country == null)
            {
                fieldsFailedValidation.Add("Country");
            }
            if (IsFieldRequired("RequireState", programConfig) && model.State == null)
            {
                fieldsFailedValidation.Add("State");
            }
            if (IsFieldRequired("RequireZip", programConfig) && string.IsNullOrEmpty(model.PostalCode))
            {
                fieldsFailedValidation.Add("Postal Code");
            }
            if (IsFieldRequired("RequireProgram", programConfig) && model.ProgramID == null)
            {
                fieldsFailedValidation.Add("Program");
            }
            if (IsFieldRequired("RequireEmail", programConfig) && string.IsNullOrEmpty(model.Email))
            {
                fieldsFailedValidation.Add("Email");
            }
            if (IsFieldRequired("RequireEffectiveDate", programConfig) && model.EffectiveDate == null)
            {
                fieldsFailedValidation.Add("Effective Date");
            }
            if (IsFieldRequired("RequireExpirationDate", programConfig) && model.ExpirationDate == null)
            {
                fieldsFailedValidation.Add("Expiration Date");
            }


            return fieldsFailedValidation;
        }

        private bool IsFieldRequired(string fieldName, List<ProgramInformation_Result> programConfig)
        {
            return programConfig.Where(x => fieldName.Equals(x.Name, StringComparison.InvariantCultureIgnoreCase) &&
                                            "yes".Equals(x.Value, StringComparison.InvariantCultureIgnoreCase)).Count() > 0;
        }

        /// <summary>
        /// Get the Blank Address
        /// </summary>
        /// <param name="recordId">The record id.</param>
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
        /// <param name="Country">The country.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetComboBoxState(int Country)
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetStateProvinces(Country).ToSelectListItem(id => id.ID.ToString(), code => code.Name);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get Member ID
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve the details for the member</exception>
        public ActionResult GetMemberID(int memberID, int membershipID)
        {
            logger.InfoFormat("MemeberController - GetMemberID() -memberID : {0} - membershipID : {1}", memberID, membershipID);
            Member memberDetails = new MemberFacade().GetMemberDetailsbyID(memberID);
            if (memberDetails == null)
            {
                throw new DMSException("Unable to retrieve the details for the member");
            }

            DMSCallContext.MemberProgramID = memberDetails.ProgramID.Value;
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside GetMemberID() of Member. Call by the grid with the userId {0} - {1}, try to returns the Json object", memberID, membershipID);
            DMSCallContext.MembershipID = membershipID;
            DMSCallContext.MemberID = memberID;
            return Json(new { MemberID = memberID, MembershipID = membershipID }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// _SearchServiceRequestHistrory Method for Service Request History Grid
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="memberId">The member id.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
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
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }


        /// <summary>
        /// Display Member Details
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberDetails(int memberID, int membershipID)
        {
            logger.InfoFormat("MemberController - GetMemberDetails() - Loading member {0} details", memberID);

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
                model.ProgramServiceEventLimit = facade.GetProgramServiceEventLimit(DMSCallContext.MemberProgramID);
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
            logger.InfoFormat("MemberController - GetMemberDetails() - Program allows payment processing : {0}", allowPayment);
            //TFS : 452
            if (DMSCallContext.MemberProgramID > 0)
            {
                var programInfoResult = repository.GetProgramInfo(DMSCallContext.MemberProgramID, "Application", "Rule");
                bool allowMemberExpirationUpdate = false;
                var itemMemberExpirationUpdate = result.Where(x => (x.Name.Equals("AllowMemberExpirationUpdate", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (itemMemberExpirationUpdate != null)
                {
                    allowMemberExpirationUpdate = true;
                }
                ViewData["AllowMemberExpirationUpdate"] = allowMemberExpirationUpdate;
                logger.InfoFormat("MemberController - GetMemberDetails() - Program allows Member Expiration Date : {0} for Member ID : {1}", allowMemberExpirationUpdate, DMSCallContext.MemberID);

                bool allowMemberNameChange = false;
                var itemMemberNameChange = result.Where(x => (x.Name.Equals("AllowMemberNameChange", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (itemMemberNameChange != null)
                {
                    allowMemberNameChange = true;
                }

                ViewData["AllowMemberNameChange"] = allowMemberNameChange;
                logger.InfoFormat("MemberController - GetMemberDetails() - Program allows Member Name Change : {0} for Member ID : {1}", allowMemberNameChange, DMSCallContext.MemberID);
            }

            //TFS #556:
            MemberManagementFacade memberManagefacade = new MemberManagementFacade();
            model.MemberProducts = memberManagefacade.GetMemberProducts(DMSCallContext.MemberID, null, null);
            return PartialView("_SearchDetailsPopUp", model);
        }

        /// <summary>
        /// Perform Search on member.
        /// </summary>
        /// <param name="isFromConnect">True or False.</param>
        /// <param name="memberPhoneNumber">Customer Phone Number. (expecting area code plus number ex.1 8001112222)</param>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.AllStateProvince, false)]
        [NoCache]
        public ActionResult Search(bool isFromConnect, string memberPhoneNumber)
        {
            if (isFromConnect == true)
            {
                logger.Info("Inside Search() of Member Controller");
                ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetProgramForMember(DMSCallContext.ProgramID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);//ReferenceDataRepository.GetDataGroupPrograms((Guid)GetLoggedInUser().ProviderUserKey, string.Empty).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
                var connectInfo = new List<SearchMember_Result>();

                ViewData["memberPhoneNumber"] = memberPhoneNumber;
                //TODO: Amazon Connect
                connectInfo.Add(new SearchMember_Result { memberPhoneNumber = memberPhoneNumber, isFromConnect = isFromConnect });
                return PartialView("_SearchMember", connectInfo);
            }
            else
            {
                logger.Info("Inside Search() of Member Controller");
                ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetProgramForMember(DMSCallContext.ProgramID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);//ReferenceDataRepository.GetDataGroupPrograms((Guid)GetLoggedInUser().ProviderUserKey, string.Empty).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
                var connectInfo = new List<SearchMember_Result>();

                ViewData["isFromConnect"] = false;
                //TODO: Amazon Connect
                connectInfo.Add(new SearchMember_Result { isFromConnect = false });
                return PartialView("_SearchMember", connectInfo);
            }

        }

        /// <summary>
        /// Perform Search on Member
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, MemberSearchCriteria searchCriteria)
        {
            logger.InfoFormat("MemberController - _Search(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                request = request,
                searchCriteria = searchCriteria
            }));
            MemberFacade facade = new MemberFacade();
            List<SearchMember_Result> list = new List<SearchMember_Result>();
            int totalRows = 0;
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
            if (string.IsNullOrEmpty(pageCriteria.WhereClause) || !string.IsNullOrEmpty(searchCriteria.CommaSepratedMemberIDList))
            {
                pageCriteria.WhereClause = null;
            }

            //Sanghi : Integration Added when we found multiple members for a given call back number
            //Idea is not to distrub existing SP and Flow, so added new SP
            if (!string.IsNullOrEmpty(searchCriteria.CommaSepratedMemberIDList))
            {
                logger.InfoFormat("Inside _Search() method in Member Controller with Member ID(s): {0}", searchCriteria.CommaSepratedMemberIDList);
                List<StartCallMemberSelections_Result> tempResult = facade.SearchMember(pageCriteria, searchCriteria.CommaSepratedMemberIDList).ToList();
                if (tempResult != null && tempResult.Count > 0)
                {
                    tempResult.ForEach(x =>
                    {
                        list.Add(new SearchMember_Result()
                        {
                            MemberID = x.MemberID,
                            MembershipID = x.MembershipID,
                            MemberNumber = x.MembershipNumber,
                            Name = x.MemberName,
                            Address = x.Address,
                            PhoneNumber = x.PhoneNumber,
                            ProgramID = x.ProgramID,
                            Program = x.Program,
                            VIN = x.VIN,
                            MemberStatus = x.MemberStatus,
                            POCount = x.POCount,
                            ClientMemberType = x.ClientMemberType
                        });
                    });
                    totalRows = tempResult.Count();
                    logger.InfoFormat("Call the view by sending {0} number of records, {1}", totalRows, JsonConvert.SerializeObject(new
                    {
                        result = tempResult
                    }));
                    return Json(new DataSourceResult() { Data = list, Total = totalRows });
                }
            }

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
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId();

                //Lakshmi - Hagerty Integration
                //Begin
                if (DMSCallContext.HagertyIntegrationConfigFlag)
                {
                    bool isHagertyProgram = DMSCallContext.IsAHagertyParentProgram;

                    if (isHagertyProgram)
                    {
                        AddressFacade addressFacade = new AddressFacade();
                        int? _stateID = null;
                        string stateAbbreviation = string.Empty;
                        if (!string.IsNullOrEmpty(searchCriteria.State))
                        {
                            _stateID = Convert.ToInt32(searchCriteria.State.ToString());
                        }

                        if (_stateID != null)
                        {
                            stateAbbreviation = addressFacade.GetStateAbbreviation(_stateID);
                        }
                        if (!string.IsNullOrEmpty(searchCriteria.MemberNumber))
                        {
                            //if ((DMSCallContext.HagertyMembershipNo != null) & (searchCriteria.MemberNumber != DMSCallContext.HagertyMembershipNo))           //Commented lines by lakshmi
                            //{
                            DMSCallContext.HagertyMembershipNo = searchCriteria.MemberNumber.ToString();
                            logger.InfoFormat("Inside _Search() method in Member Controller, trying to Get Member Information From Hagerty with Member Number : {0}, Is Hagerty Program : {1}, First Name : {2}, Last Name : {3}, State Abbreviation : {4}, Zip Code : {5}, User : {6}, Inbound Call Id: {7}, Program ID : {8} ", searchCriteria.MemberNumber, isHagertyProgram, searchCriteria.FirstName, searchCriteria.LastName, stateAbbreviation, searchCriteria.ZipCode, loggedInUserName, inboundCallId, searchCriteria.ProgramID);
                            facade.GetMemberInformationFromHagerty(searchCriteria.MemberNumber, isHagertyProgram, searchCriteria, stateAbbreviation, loggedInUserName, Request.RawUrl, inboundCallId,
                                searchCriteria.ProgramID, HttpContext.Session.SessionID, searchCriteria.EmployeeInd);
                            //}
                            //logger.InfoFormat("Inside _Search() method in Member Controller, Hagerty Membership Number : {0}", DMSCallContext.HagertyMembershipNo);
                        }
                        else if (!string.IsNullOrEmpty(searchCriteria.FirstName)
                            & !string.IsNullOrEmpty(searchCriteria.LastName)
                            & !string.IsNullOrEmpty(stateAbbreviation)
                            & !string.IsNullOrEmpty(searchCriteria.ZipCode))
                        {

                            logger.InfoFormat("Inside _Search() method in Member Controller, trying to Get Member Information From Hagerty with Member Number : {0}, Is Hagerty Program : {1}, First Name : {2}, Last Name : {3}, State Abbreviation : {4}, Zip Code : {5}, User : {6}, Inbound Call Id: {7}, Program ID : {8} ", searchCriteria.MemberNumber, isHagertyProgram, searchCriteria.FirstName, searchCriteria.LastName, stateAbbreviation, searchCriteria.ZipCode, loggedInUserName, inboundCallId, searchCriteria.ProgramID);
                            facade.GetMemberInformationFromHagerty(searchCriteria.MemberNumber, isHagertyProgram, searchCriteria, stateAbbreviation.Trim(), loggedInUserName, Request.RawUrl, inboundCallId,
                                  searchCriteria.ProgramID, HttpContext.Session.SessionID, searchCriteria.EmployeeInd);
                        }
                    }
                }
                //End
                logger.InfoFormat("Inside _Search() method in Member Controller, trying to Search Member with Params User : {0}, Inbound Call Id: {1}, Program ID : {2} ", loggedInUserName, inboundCallId, searchCriteria.ProgramID);
                list = facade.SearchMember(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, searchCriteria.ProgramID, HttpContext.Session.SessionID);


                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
            }

            logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
            if (!searchCriteria.MemberFoundFromMobile)
            {
                DMSCallContext.MobileCallForServiceRecord = null;
            }
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }


        /// <summary>
        /// Retrieve Member Details
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult MemberDetails()
        {
            //logger.Info("Entering into Member Tab.");
            logger.InfoFormat("MemberController - MemberDetails() - Loading member details for membership ID : {0}", DMSCallContext.MemberID);
            int memberID = DMSCallContext.MemberID;
            int membershipID = DMSCallContext.MembershipID;

            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            MemberFacade facade = new MemberFacade();
            MemberManagementFacade memberManagementfacade = new MemberManagementFacade();

            MemberDetailsModel memberModel = new MemberDetailsModel();
            memberModel.MemberProductsList = memberManagementfacade.GetMemberProducts(memberID, new PageCriteria() { StartInd = 1, EndInd = 10, PageSize = 10 });
            memberModel.MembershipContactInformation = facade.GetMembershipContactInformation(memberID);
            DMSCallContext.MemberEmail = memberModel.MembershipContactInformation.EMail;
            memberModel.MembershipInformation = facade.GetMembershipInformation(memberID);

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


            bool allowPayment = false;
            var itemAllowPaymentProcessing = result.Where(x => (x.Name.Equals("AllowPaymentProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (itemAllowPaymentProcessing != null)
            {
                allowPayment = true;
            }
            DMSCallContext.AllowPaymentProcessing = allowPayment;
            logger.InfoFormat("MemberController - MemberDetails() - Program allows payment processing : {0}", allowPayment);
            bool allowEstimate = false; //AllowEstimateProcessing
            var itemallowEstimateProcessing = result.Where(x => (x.Name.Equals("AllowEstimateProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (itemallowEstimateProcessing != null)
            {
                allowEstimate = true;
            }
            DMSCallContext.AllowEstimateProcessing = allowEstimate;
            logger.InfoFormat("MemberController - MemberDetails() - Program allows estimate processing : {0}", allowEstimate);
            #endregion

            if (memberModel.MembershipContactInformation != null)
            {
                ViewData[Martex.DMS.ActionFilters.StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(memberModel.MembershipContactInformation.CountryID.HasValue ? memberModel.MembershipContactInformation.CountryID.Value : 1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, false);
            }
            else
            {
                ViewData[Martex.DMS.ActionFilters.StaticData.Province.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => y.Abbreviation.Trim() + "-" + y.Name, false);
            }

            if (DMSCallContext.ProgramID > 0)
            {
                var clientRepository = new ClientRepository();
                Client cl = clientRepository.GetClientByProgram(DMSCallContext.ProgramID);
                if (cl != null)
                {
                    DMSCallContext.ClientName = cl.Name;
                }
                POFacade poFacade = new POFacade();

                var hasAccountingInvoiceBatchID = poFacade.GetSRHasAccountingInvoiceBatchID(DMSCallContext.ServiceRequestID);
                bool allowMemberExpirationUpdate = false;
                bool allowMemberNameChange = false;
                bool allowMemberProgramChange = false;

                if (!hasAccountingInvoiceBatchID)
                {
                    var programInfoResult = repository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");

                    var itemMemberExpirationUpdate = programInfoResult.Where(x => (x.Name.Equals("AllowMemberExpirationUpdate", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                    if (itemMemberExpirationUpdate != null)
                    {
                        allowMemberExpirationUpdate = true;
                    }
                    logger.InfoFormat("MemberController - MemberDetails() - Allow Member Expiration Update of Program : {0} is {1}", DMSCallContext.ProgramID, allowMemberExpirationUpdate);

                    var itemMemberNameChange = programInfoResult.Where(x => (x.Name.Equals("AllowMemberNameChange", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                    if (itemMemberNameChange != null)
                    {
                        allowMemberNameChange = true;
                    }

                    var itemMemberProgramChange = programInfoResult.Where(x => (x.Name.Equals("AllowMemberProgramChange", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                    if (itemMemberProgramChange != null)
                    {
                        allowMemberProgramChange = true;
                    }
                    var vendorInvoiceRepository = new VendorInvoiceRepository();
                    int vendorInvoiceCountForSR = vendorInvoiceRepository.GetVendorInvoiceCountForSR(DMSCallContext.ServiceRequestID);
                    if (vendorInvoiceCountForSR > 0)
                    {
                        allowMemberProgramChange = false;
                    }
                }
                ViewData["AllowMemberExpirationUpdate"] = allowMemberExpirationUpdate;
                logger.InfoFormat("Program allows Member Expiration Date : {0}", allowMemberExpirationUpdate);

                ViewData["AllowMemberNameChange"] = allowMemberNameChange;
                logger.InfoFormat("MemberController - MemberDetails() - Program allows Member Name Change : {0} for Member ID : {1}", allowMemberNameChange, DMSCallContext.MemberID);


                ViewData["AllowMemberProgramChange"] = allowMemberProgramChange;
                logger.InfoFormat("MemberController - MemberDetails() - Program allows Member Program Change : {0} for Member ID : {1}", allowMemberProgramChange, DMSCallContext.MemberID);

                ViewData["TransitionProgramForMember"] = ReferenceDataRepository.GetTransitionProgramForMember(DMSCallContext.ProgramID).ToSelectListItem<ChildrenPrograms_Result>(x => x.ProgramID.ToString(), y => y.ProgramName, true);
            }
            DMSCallContext.MemberStatus = memberModel.MembershipInformation.MemberStatus;

            //TFS:163
            SetTabValidationStatus(RequestArea.MEMBER);
            return PartialView("_MemberDetails", memberModel);
        }

        [NoCache]
        public ActionResult _MemberClaimsHistory()
        {
            int memberId = DMSCallContext.MemberID;
            return PartialView("_MemberClaimsHistory", memberId);
        }

        [NoCache]
        [HttpPost]
        public ActionResult _MemberClaimsRead([DataSourceRequest] DataSourceRequest request, int memberId)
        {
            logger.InfoFormat("MemeberController - _MemberClaimsRead(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request,
                memberId = memberId
            }));
            MemberManagementFacade facade = new MemberManagementFacade();
            logger.Info("Inside _MemberClaimsRead of Member Controller. Attempt to get all Claims depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClaimDate";
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
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<Member_Claims_Result> list = facade.GetmemberClaims(memberId, null, pageCriteria);
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

            return Json(result);
        }

        /// <summary>
        /// Save Member Details
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult SaveMemberDetails(MembershipContactInformation model)
        {
            logger.InfoFormat("MemeberController - SaveMemberDetails(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                MembershipID = DMSCallContext.MembershipID,
                MemberID = DMSCallContext.MemberID,
                MembershipContactInformation = model
            }));
            //logger.InfoFormat("Inside SaveMemberDetails() in MemberController with MemberID : {0} and MemberShipID : {1}", DMSCallContext.MemberID, DMSCallContext.MembershipID);
            OperationResult result = new OperationResult();
            MemberFacade facade = new MemberFacade();
            model.MemberID = DMSCallContext.MemberID;
            model.MemberShipID = DMSCallContext.MembershipID;
            logger.Info("Saving Member Contact Information");
            facade.SaveMemberContactInformation(model, GetLoggedInUser().UserName, Request.RawUrl, DMSCallContext.ServiceRequestID, DMSCallContext.CaseID, Session.SessionID);
            logger.Info("Saved Member Contact Information Successfully");
            // Update the DMSCallContext - Callback numbers
            DMSCallContext.StartCallData.ContactPhoneNumber = model.CallbackNumber.PhoneNumber;
            DMSCallContext.StartCallData.ContactPhoneTypeID = model.CallbackNumber.PhoneTypeID;
            DMSCallContext.ContactFirstName = model.FirstName;
            DMSCallContext.ContactLastName = model.LastName;

            DMSCallContext.StartCallData.ContactAltPhoneNumber = model.AlternateCallbackNumber.PhoneNumber;
            DMSCallContext.StartCallData.ContactAltPhoneTypeID = model.AlternateCallbackNumber.PhoneTypeID;

            DMSCallContext.IsDeliveryDriver = model.IsDeliveryDriver;
            result.Status = OperationStatus.SUCCESS;

            //OnLeave();
            return Json(result);
        }

        /// <summary>
        /// ListResult Method for Search Request History Grid
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult ListResult([DataSourceRequest] DataSourceRequest request)
        {
            //logger.Info("Inside ListResult() of MemeberController. Attempt to get all Members depending upon the GridCommand");
            logger.InfoFormat("MemeberController - ListResult() : Parameters{0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request
            }));
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "UserName";
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
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = GetWhereClauseXMLForAssociateList(this.MemberShipID)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            MemberFacade facade = new MemberFacade();
            logger.InfoFormat("Retrieving Member's SR History for : {0}", JsonConvert.SerializeObject(new
            {
                MembershipID = DMSCallContext.MembershipID
            }));
            List<MemberServiceRequestHistory_Result> list = facade.GetMemberServiceRequestHistory(pageCriteria);
            logger.InfoFormat("Retrieved Member's SR History Successfully : {0}", JsonConvert.SerializeObject(new
            {
                Count = list != null ? list.Count : 0
            }));
            logger.Info("Retrieving Member's SR History Filtered List");
            List<MemberServiceRequestHistory_Result> Filterlist = list.Where(u => u.ServiceRequestNumber != DMSCallContext.ServiceRequestID).ToList();
            logger.InfoFormat("Retrieved Member's SR History Filtered List Successfully: {0}", JsonConvert.SerializeObject(new
            {
                Count = Filterlist != null ? Filterlist.Count : 0
            }));
            int totalRows = 0;
            logger.InfoFormat("Call the view by sending {0} number of records", Filterlist.Count);
            if (Filterlist.Count > 0)
            {
                totalRows = Filterlist[0].TotalRows.Value;
            }

            var result = new DataSourceResult()
            {
                Data = Filterlist,
                Total = totalRows
            };

            return Json(result);
        }


        /// <summary>
        /// List Method for Memebers List Grid
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            //logger.Info("Inside List() of MemeberController. Attempt to get all Memebers depending upon the GridCommand");
            logger.InfoFormat("MemeberController - List() : Parameters{0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request
            }));
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
            return Json(result);
        }

        /// <summary>
        /// Get Service Request ID
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public ActionResult GetServiceRequestId(string serviceRequestID)
        {
            OperationResult result = new OperationResult();

            //logger.InfoFormat("Inside GetServiceRequestId() of UserController. Call by the grid with the serviceRequestID {0}, try to returns the Json object", serviceRequestID);
            logger.InfoFormat("MemeberController - GetServiceRequestId() : Parameters{0}", JsonConvert.SerializeObject(new
            {
                serviceRequestID = serviceRequestID
            }));
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
            logger.InfoFormat("Inside _GetHomeAddress() in MemebrController");
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
                                               addressEntity.StateProvince == null ? string.Empty : addressEntity.StateProvince.Trim(),
                                               addressEntity.PostalCode == null ? string.Empty : addressEntity.PostalCode,
                                               addressEntity.CountryCode == null ? string.Empty : addressEntity.CountryCode);
            }
            logger.InfoFormat("MemeberController - _GetHomeAddress() : Returns {0}", JsonConvert.SerializeObject(new
            {
                Address = result.Data
            }));


            return Json(result, JsonRequestBehavior.AllowGet);
        }


        //
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetSellerDelaerLocation()
        {
            logger.InfoFormat("Inside _GetSellerDelaerLocation() in MemebrController");
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            AddressRepository addressRepository = new AddressRepository();
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            Member member = new MemberRepository().Get(DMSCallContext.MemberID);
            Vendor vendor = null;
            int? vendorLocationID = null;
            AddressEntity addressEntity = null;

            if (member.SellerVendorID != null)
            {
                addressEntity = addressRepository.GetAddresses(member.SellerVendorID.GetValueOrDefault(), "Vendor", "Business").FirstOrDefault();
                vendor = new VendorRepository().GetByID(member.SellerVendorID.Value);
                if (vendor != null)
                {
                    var vendorLocations = vendorFacade.GetVendorLocationsList(member.SellerVendorID.Value);
                    if (vendorLocations != null && vendorLocations.Count > 1)
                    {
                        vendorLocationID = vendorLocations[1].VendorLocationID;
                    }
                }
                result.Data = new
                {
                    VendorID = member.SellerVendorID.GetValueOrDefault(),
                    VendorName = vendor != null ? vendor.Name : string.Empty,
                    VendorLocationID = vendorLocationID,
                    VendorAddress = string.Join(",", addressEntity.Line1 == null ? string.Empty : addressEntity.Line1,
                                                      addressEntity.City == null ? string.Empty : addressEntity.City,
                                                      addressEntity.StateProvince == null ? string.Empty : addressEntity.StateProvince.Trim(),
                                                      addressEntity.PostalCode == null ? string.Empty : addressEntity.PostalCode,
                                                      addressEntity.CountryCode == null ? string.Empty : addressEntity.CountryCode)
                };
            }

            logger.InfoFormat("MemberController - _GetSellerDelaerLocation() : Returns {0}", JsonConvert.SerializeObject(new
            {
                VendorDetails = result.Data
            }));

            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            long eventLogID = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.USE_SELLER_DEALER_LOCATION, "Use SellerDealer Location", LoggedInUserName, Session.SessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);


            return Json(result, JsonRequestBehavior.AllowGet);
        }


        public ActionResult OpenedMembershipNote(int? membershipID)
        {
            OperationResult result = new OperationResult();

            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            long eventLogID = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.OPENED_MEMBERSHIP_NOTE, "Opened Membership Note", LoggedInUserName, Session.SessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, DMSCallContext.InboundCallID, EntityNames.INBOUND_CALL);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, membershipID, EntityNames.MEMBERSHIP);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Updates the members expiration date.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult UpdateMembersExpirationDate(DateTime? expirationDate, string comments)
        {
            logger.InfoFormat("Inside UpdateMembersExpirationDate() in MemebrController for Member : {0}", DMSCallContext.MemberID);
            OperationResult result = new OperationResult();
            try
            {
                MemberFacade facade = new MemberFacade();
                DateTime? date = expirationDate;
                if (expirationDate.HasValue)
                {

                    date = date.Value.AddDays(1);
                    date = date.Value.AddSeconds(-1);
                }

                DMSCallContext.MemberStatus = facade.UpdateMembersExpirationDate(date, comments, DMSCallContext.MemberID, DMSCallContext.ServiceRequestID, LoggedInUserName, Session.SessionID, Request.RawUrl, DMSCallContext.ProgramID, DMSCallContext.ProductCategoryID, DMSCallContext.PrimaryProductID, DMSCallContext.VehicleTypeID, DMSCallContext.VehicleCategoryID, DMSCallContext.IsPossibleTow, DMSCallContext.CaseID);

                CaseFacade cf = new CaseFacade();
                var c = cf.GetCaseById(DMSCallContext.CaseID);
                if (c != null)
                {
                    DMSCallContext.MemberStatus = c.MemberStatus;
                }

                logger.Info("Updated MembersExpirationDate Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message;
                logger.Error(ex.Message);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveMemberName(string firstName, string middleName, string lastName)
        {
            logger.InfoFormat("Inside SaveMemberName() in MemebrController for Member : {0}", DMSCallContext.MemberID);
            OperationResult result = new OperationResult();
            try
            {
                MemberFacade facade = new MemberFacade();
                facade.SaveMemberName(firstName, middleName, lastName, DMSCallContext.MemberID, DMSCallContext.InboundCallID, DMSCallContext.CaseID, DMSCallContext.ServiceRequestID, LoggedInUserName, Session.SessionID, Request.RawUrl);

                logger.Info("Updated Member Name Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message;
                logger.Error(ex.Message);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        //
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult UpdateMembersProgram(string programID, string comments)
        {
            logger.InfoFormat("Inside UpdateMembersProgram() in MemebrController for Member : {0}", DMSCallContext.MemberID);
            OperationResult result = new OperationResult();
            try
            {
                var newProgramID = int.Parse(programID);
                MemberFacade facade = new MemberFacade();
                facade.UpdateMembersProgram(newProgramID, comments, DMSCallContext.ProgramID, DMSCallContext.MemberID, DMSCallContext.InboundCallID, DMSCallContext.CaseID, DMSCallContext.ServiceRequestID, LoggedInUserName, Session.SessionID, Request.RawUrl);
                DMSCallContext.ProgramID = newProgramID;

                logger.Info("Updated Member Program Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message;
                logger.Error(ex.Message);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveMemberExpirationDate(DateTime? expirationDate, string comments)
        {
            logger.InfoFormat("Inside SaveMemberExpirationDate() in MemebrController for Member : {0}", DMSCallContext.MemberID);
            OperationResult result = new OperationResult();
            try
            {
                DateTime? date = expirationDate;
                if (expirationDate.HasValue)
                {

                    date = date.Value.AddDays(1);
                    date = date.Value.AddSeconds(-1);
                }
                MemberFacade facade = new MemberFacade();
                facade.SaveMembersExpirationDate(date, comments, DMSCallContext.MemberID, DMSCallContext.InboundCallID, DMSCallContext.CaseID, LoggedInUserName, Session.SessionID, Request.RawUrl);

                logger.Info("Updated MembersExpirationDate Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message;
                logger.Error(ex.Message);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult _GetProgramCoverageInformationList([DataSourceRequest] DataSourceRequest request)
        {
            logger.InfoFormat("MemeberController - _GetProgramCoverageInformationList(), Attempt to get all Program Coverage Information depending upon the GridCommand : {0}", JsonConvert.SerializeObject(new
            {
                request = request
            }));
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            int? programID = DMSCallContext.MemberProgramID;
            MemberFacade facade = new MemberFacade();
            List<ProgramCoverageInformationList_Result> list = facade.GetProgramCoverageInformationList(pageCriteria, programID);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }
        #endregion

        #region Member Products
        [DMSAuthorize]
        [NoCache]
        public ActionResult _MemberProducts()
        {
            int memberId = DMSCallContext.MemberID;
            return PartialView(memberId);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _MemberProductsUsingCategory(int? serviceTypeId = null)
        {
            MemberManagementFacade facade = new MemberManagementFacade();
            string vinNumber = string.Empty;
            if (DMSCallContext.CaseID > 0)
            {
                CaseFacade caseFacade = new CaseFacade();
                Case caseDetails = caseFacade.GetCaseById(DMSCallContext.CaseID);
                vinNumber = caseDetails == null ? string.Empty : caseDetails.VehicleVIN;
            }
            return PartialView(facade.GetMemberProducts(DMSCallContext.MemberID, serviceTypeId.HasValue ? serviceTypeId.GetValueOrDefault() : DMSCallContext.ProductCategoryID, vinNumber));
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _MemberProductsListUsingCategory(int? serviceTypeId = null)
        {
            OperationResult result = new OperationResult();
            MemberManagementFacade facade = new MemberManagementFacade();
            string vinNumber = string.Empty;
            if (DMSCallContext.CaseID > 0)
            {
                CaseFacade caseFacade = new CaseFacade();
                Case caseDetails = caseFacade.GetCaseById(DMSCallContext.CaseID);
                vinNumber = caseDetails == null ? string.Empty : caseDetails.VehicleVIN;
            }
            result.Data = facade.GetMemberProducts(DMSCallContext.MemberID, serviceTypeId.HasValue ? serviceTypeId.GetValueOrDefault() : DMSCallContext.ProductCategoryID, vinNumber);
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        [NoCache]
        [HttpPost]
        public ActionResult _MemberProductsList([DataSourceRequest] DataSourceRequest request, int memberId)
        {
            MemberManagementFacade facade = new MemberManagementFacade();
            logger.Info(string.Format("Inside Member Products. Attempt to get member products for member id {0}", memberId));
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Product";
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
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<MemberProducts_Result> list = facade.GetMemberProducts(memberId, pageCriteria);
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

            return Json(result);
        }
        #endregion

    }
}
