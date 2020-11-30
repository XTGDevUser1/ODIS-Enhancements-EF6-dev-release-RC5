using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Areas.Application.Controllers;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Claims.Controllers
{
    [DMSAuthorize]
    public partial class ClaimController : VehicleBaseController
    {
        ClaimsFacade facade = new ClaimsFacade();

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLAIMS_CLAIMS)]
        public ActionResult Index()
        {
            ClaimSearchCriteria model = null;
            model = model.GetModelForSearchCriteria();
            logger.Info("Trying to Retrieve Claim Status");
            return View(model);
        }

        [HttpPost]
        [ReferenceDataFilter(StaticData.ClaimIDFilterTypes, true)]
        [ReferenceDataFilter(StaticData.ClaimNameFilterTypes, true)]
        [ReferenceDataFilter(StaticData.SearchFilterTypes, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        [ReferenceDataFilter(StaticData.ExportBatchesForClaim, true)]
        public ActionResult _SearchCriteria(ClaimSearchCriteria model)
        {
            ClaimSearchCriteria tempModel = model;
            ModelState.Clear();
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(model.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);
            if (model.FilterToLoadID.HasValue)
            {
                ClaimSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as ClaimSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        public ActionResult _SelectedCriteria(ClaimSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Claims the search.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult ClaimSearch([DataSourceRequest] DataSourceRequest request, ClaimSearchCriteria model)
        {
            logger.Info("Inside ClaimSearch of Claims Controller. Attempt to get all Claims depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClaimDate";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterClause();

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
            List<ClaimsList_Result> list = new List<ClaimsList_Result>();
            if (filter.Count > 0)
            {
                list = facade.GetClaimsList(pageCriteria);
            }
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
        /// Deletes the claim.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        public ActionResult DeleteClaim(int claimID)
        {
            OperationResult result = new OperationResult();
            facade.DeleteClaim(claimID);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the claim details.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.PayeeType, true)]
        [ReferenceDataFilter(StaticData.ClaimStatus, true)]
        [ReferenceDataFilter(StaticData.ContactMethodForClaim, true)]
        [ReferenceDataFilter(StaticData.ClaimRejectReason, true)]
        [ReferenceDataFilter(StaticData.FinishUsers, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.ACESClaimStatus, false)]
        public ActionResult _ClaimDetails(int? claimID)
        {
            ViewData[StaticData.NextAction.ToString()] = ReferenceDataRepository.NextActions(EntityNames.CLAIM).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            ViewData[StaticData.MemberShipMembers.ToString()] = ReferenceDataRepository.GetMembersByMembershipNumber(string.Empty).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
            var programsAsSelectListItem = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
            ViewData["Programs"] = programsAsSelectListItem;
            ViewData["OwnerPrograms"] = ReferenceDataRepository.GetOwnerProgramsForClaim().ToSelectListItem(x => x.ID.ToString(), y => y.Name.ToString());
            ViewData["ClaimTypes"] = ReferenceDataRepository.GetClaimTypesExcept("FordQFC").ToSelectListItem<ClaimType>(x => x.ID.ToString(), y => y.Description, true);
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);

            ViewData["WarrantyPrograms"] = ReferenceDataRepository.GetProgramsForSearchByClaimType("MotorhomeReimbursementClaim").ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData["RoadsidePrograms"] = programsAsSelectListItem;//ReferenceDataRepository.GetProgramsForSearchByClaimType("RoadsideReimbursementClaim").ToSelectListItem(x => x.ID.ToString(), y => y.Name);


            if (claimID == null)
            {
                claimID = 0;
            }
            // Loading Basic Information
            ClaimInformationModel model = InitlizeClaimInformationDetails(claimID.GetValueOrDefault());
            // Loading Vehicle Section Details
            InitlizeVehcileInformation(model);
            if (model.Claim.PaymentAddressCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(model.Claim.PaymentAddressCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }

            if (!string.IsNullOrEmpty(model.MembershipNumber))
            {
                ViewData[StaticData.MemberShipMembers.ToString()] = ReferenceDataRepository.GetMembersByMembershipNumber(model.MembershipNumber).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, true);
            }
            if (model.Claim.ClaimTypeID.HasValue)
            {
                //ClaimType motorClaim = ReferenceDataRepository.GetClaimTypes().Where(x=>x.ID == model.Claim.ClaimTypeID.Value).FirstOrDefault<ClaimType>();
                //if (motorClaim.Name == ClaimTypeName.MOTOR_HOME_REIMBURSEMENT)
                //{
                //    ACESClaimStatu acesclaimStatus = ReferenceDataRepository.GetAcesClaimStatus().Where(x => x.Name == "Pending").FirstOrDefault<ACESClaimStatu>();
                //    model.Claim.ACESClaimStatusID = acesclaimStatus.ID;
                //}
                ViewData[StaticData.ClaimCategory.ToString()] = ReferenceDataRepository.GetClaimCategoryBaseOnClaim(model.Claim.ClaimTypeID.Value).ToSelectListItem<ClaimCategory>(x => x.ID.ToString(), y => y.Description, true);
            }
            else
            {
                ViewData[StaticData.ClaimCategory.ToString()] = ReferenceDataRepository.GetClaimCategories().ToSelectListItem<ClaimCategory>(x => x.ID.ToString(), y => y.Description, true);
            }
            return View(model);
        }

        [DMSAuthorize]
        public ActionResult _MemberAddressAndPhoneNumber(int memberID)
        {
            logger.InfoFormat("Executing LookUp for Member Address and Phone Number member ID {0}", memberID);
            OperationResult result = new OperationResult();
            var facade = new ClaimsFacade();
            var addressDetails = facade.LookUpMemberAddressDetails(memberID);
            if (addressDetails == null)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                logger.InfoFormat("Details not available for Member ID {0}", memberID);
            }
            else
            {
                result.Status = OperationStatus.SUCCESS;
                result.Data = new
                {
                    Details = addressDetails
                };
                logger.InfoFormat("Details found for Member ID {0}", memberID);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult _ValidatePONumber(string poNumber)
        {
            logger.InfoFormat("Executing LookUp for Purchase Order Number {0}", poNumber);
            OperationResult result = new OperationResult();
            var facade = new ClaimsFacade();
            var purchaseOrderDetails = facade.LookUpPurchaseOrderNumber(poNumber);
            if (purchaseOrderDetails == null)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.Data = new { Message = string.Format("Purchase Order {0} number not found. Please try again.", poNumber) };
                logger.InfoFormat("Details not available for Purchase Order Number {0}", poNumber);
            }
            else
            {
                result.Status = OperationStatus.SUCCESS;
                result.Data = new
                    {
                        Message = string.Format("Membership: {0} - {1} - {2} <br> Vendor: {3} - {4}", purchaseOrderDetails.MembershipNumber, purchaseOrderDetails.ProgramName, purchaseOrderDetails.MemberName, purchaseOrderDetails.VendorNumber, purchaseOrderDetails.VendorName),
                        Details = purchaseOrderDetails
                    };
                logger.InfoFormat("Details found for Purchase Order Number {0}", poNumber);
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult _ValidateMembershipNumber(int? programID, string searchTerm, string type)
        {

            List<SearchMembersByVINOrMS_Result> list = new List<SearchMembersByVINOrMS_Result>();
            var emptyItem = new SearchMembersByVINOrMS_Result()
            {

            };
            if (string.IsNullOrEmpty(searchTerm))
            {
                emptyItem.MemberNumber = "Please enter something to search on";
                list.Clear();
                list.Add(emptyItem);
            }
            else
            {
                if ("ms".Equals(type))
                {
                    //TFS  : 601
                    if (DMSCallContext.CheckIfHagertyParentProgram(programID.GetValueOrDefault()))
                    {
                        logger.InfoFormat("ClaimController - _ValidateMembershipNumber : {0} is a Hagerty Parent Program. So Trying get information from Hagerty Web Service", programID.GetValueOrDefault());
                        MemberFacade memberFacade = new MemberFacade();
                        memberFacade.GetMemberInformationFromHagerty(searchTerm, true, null, string.Empty, LoggedInUserName, Request.RawUrl, 0, programID.GetValueOrDefault(), Session.SessionID);
                    }
                    else
                    {
                        logger.InfoFormat("ClaimController - _ValidateMembershipNumber : {0} is not a Hagerty Parent Program", programID.GetValueOrDefault());
                    }

                    list = facade.SearchByMembershipAndProgram(searchTerm, programID);
                }
                else
                {
                    list = facade.SearchByVINAndProgram(searchTerm, programID);
                }
                if (list.Count == 0)
                {
                    emptyItem.MemberNumber = "No members found.Please adjust the search criteria and try again";
                    list.Clear();
                    list.Add(emptyItem);
                }
            }

            ComboGridModel gridModel = new ComboGridModel()
            {
                Count = list.Count,
                records = list.Count,
                total = list.Count,
                rows = list.ToArray<SearchMembersByVINOrMS_Result>()
            };
            return Json(gridModel, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult _ValidateSR(string searchTerm)
        {
            List<Queue_Result> list = new List<Queue_Result>();
            var emptyItem = new Queue_Result()
            {

            };
            if (string.IsNullOrEmpty(searchTerm))
            {
                emptyItem.MemberNumber = "Please enter something to search on";
                list.Clear();
                list.Add(emptyItem);
            }
            else
            {
                list = facade.SearchBySR(searchTerm, GetLoggedInUserId());
                if (list.Count == 0)
                {
                    emptyItem.MemberNumber = "No Service reqeusts found.Please adjust the search criteria and try again";
                    list.Clear();
                    list.Add(emptyItem);
                }
            }

            ComboGridModel gridModel = new ComboGridModel()
            {
                Count = list.Count,
                records = list.Count,
                total = list.Count,
                rows = list.ToArray<Queue_Result>()
            };
            return Json(gridModel, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult _ValidateMembershipOrVendorNumber(string payeeType, string value)
        {
            var addressRepository = new AddressRepository();
            var phoneRepository = new PhoneRepository();

            OperationResult result = new OperationResult();
            result.Status = OperationStatus.BUSINESS_RULE_FAIL;

            var facade = new ClaimsFacade();
            if (payeeType.Equals("Member"))
            {
                Member memberDetails = facade.GetMemberUsingMembershipNumber(value, null);
                if (memberDetails != null)
                {
                    result.Status = OperationStatus.SUCCESS;
                    string memberName = string.Join(" ", memberDetails.FirstName, memberDetails.MiddleName, memberDetails.LastName);
                    result.Data = new
                    {
                        Message = string.Format("Membership found: {0}; click Continue", memberName),
                        ProgramID = memberDetails.ProgramID,
                        MemberID = memberDetails.ID
                    };
                }
                else
                {
                    result.Data = new { Message = string.Format("Membership not found for {0}, please try again", value) };
                }
            }
            else if (payeeType.Equals("Vendor"))
            {
                Vendor vendorDetails = facade.GetVendorByVendorNumber(value);
                if (vendorDetails != null)
                {
                    result.Status = OperationStatus.SUCCESS;
                    AddressEntity addressDetails = addressRepository.GetAddresses(vendorDetails.ID, EntityNames.VENDOR, AddressTypeNames.BILLING).FirstOrDefault();
                    PhoneEntity phoneDetails = phoneRepository.Get(vendorDetails.ID, EntityNames.VENDOR, PhoneTypeNames.Dispatch);

                    result.Data = new
                    {
                        Message = string.Format("Vendor found: {0}; click Continue", vendorDetails.Name),
                        VendorID = vendorDetails.ID,
                        VendorName = vendorDetails.Name,

                        IsAddressFound = addressDetails == null ? false : true,
                        IsPhoneFound = phoneDetails == null ? false : true,
                        Line1 = addressDetails == null ? string.Empty : addressDetails.Line1,
                        Line2 = addressDetails == null ? string.Empty : addressDetails.Line2,
                        Line3 = addressDetails == null ? string.Empty : addressDetails.Line3,
                        City = addressDetails == null ? string.Empty : addressDetails.City,
                        PostalCode = addressDetails == null ? string.Empty : addressDetails.PostalCode,
                        StateProvinceID = addressDetails == null ? string.Empty : addressDetails.StateProvinceID.GetValueOrDefault().ToString(),
                        CountryID = addressDetails == null ? string.Empty : addressDetails.CountryID.GetValueOrDefault().ToString(),
                        MemberPhoneNumber = phoneDetails == null ? string.Empty : phoneDetails.PhoneNumber,
                        MemberName = string.Join(" ", vendorDetails.ContactFirstName, vendorDetails.ContactLastName)
                    };
                }
                else
                {
                    result.Data = new { Message = string.Format("Vendor not found for {0}, please try again", value) };
                }
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public ActionResult GetClaimTypeDetails(int claimTypeID)
        {
            OperationResult result = new OperationResult();
            try
            {
                var facade = new CommonLookUpRepository();
                ClaimType details = facade.GetClaimType(claimTypeID);
                result.Data = new { IsFordACES = details.IsFordACES.GetValueOrDefault() };
            }
            catch
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
