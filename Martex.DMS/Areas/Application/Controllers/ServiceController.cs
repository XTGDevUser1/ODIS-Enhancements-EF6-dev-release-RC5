using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using System.Collections.Specialized;
using Martex.DMS.BLL.Model;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.Areas.Application.Models;
using System.Web.Script.Serialization;
using Martex.DMS.DAL.DAO;
using System.Text;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class ServiceController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [ReferenceDataFilter(StaticData.ServiceMemberPayMode, true)]
        [DMSAuthorize]
        public ActionResult Index()
        {
            logger.Info("ServiceController - Index - Started");
            var facade = new ServiceFacade();

            int programId = DMSCallContext.ProgramID;
            int? vehicleCategoryId = DMSCallContext.VehicleCategoryID;
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;

            logger.InfoFormat("ServiceController - Index - Retrieving Questionnaire for Program ID {0}, Vehcile Category ID : {1}, Vehcile Type ID {2}", programId, vehicleCategoryId, vehicleTypeId);
            List<ServiceTab> serviceTabs = facade.GetQuestionnaire(programId, vehicleCategoryId, vehicleTypeId, DMSCallContext.ServiceRequestID, DMSCallContext.SourceSystemFromCase);

            logger.InfoFormat("ServiceController - Index - Retrieving Vehicle Categories for Vehcile Type ID {0}", vehicleTypeId);
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            // JSONify Questions.
            JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
            StringBuilder jsonQuestions = new StringBuilder();
            jsonSerializer.Serialize(serviceTabs, jsonQuestions);
            ViewData["JSON_MODEL"] = jsonQuestions.ToString();

            // Get comments to be able to present them on the tech tab.
            ViewData[StringConstants.SERVICE_TECH_COMMENT] = DMSCallContext.ServiceTechComments;

            logger.InfoFormat("ServiceController - Index - Retrieving Service Tech Details for Service Request ID {0}", DMSCallContext.ServiceRequestID);

            ViewData[StringConstants.SERVICE_TECH_MODEL] = facade.GetServiceTechDetails(DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, DMSCallContext.ProgramID);
            ViewData["VehicleTypeId"] = DMSCallContext.VehicleTypeID;

            logger.InfoFormat("ServiceController - Index - Retrieving Service Tech Request By ID {0}", DMSCallContext.ServiceRequestID);
            ServiceRequest sr = facade.GetServiceRequestById(DMSCallContext.ServiceRequestID);


            ServiceEligibilityModel serviceEligibiltyModel = new ServiceEligibilityModel();


            serviceEligibiltyModel.IsSecondaryOverallCovered = sr.IsSecondaryOverallCovered;
            serviceEligibiltyModel.IsSecondaryProductCovered = sr.IsSecondaryProductCovered;
            serviceEligibiltyModel.SecondaryCoverageLimit = sr.SecondaryCoverageLimit;
            serviceEligibiltyModel.SecondaryCoverageLimitMileage = sr.SecondaryCoverageLimitMileage;
            serviceEligibiltyModel.SecondaryServiceCoverageDescription = sr.SecondaryServiceCoverageDescription;
            serviceEligibiltyModel.SecondaryServiceEligiblityMessage = sr.SecondaryServiceEligiblityMessage;

            serviceEligibiltyModel.IsPrimaryOverallCovered = sr.IsPrimaryOverallCovered;
            serviceEligibiltyModel.IsPrimaryProductCovered = sr.IsPrimaryProductCovered;
            serviceEligibiltyModel.PrimaryCoverageLimit = sr.PrimaryCoverageLimit;
            serviceEligibiltyModel.PrimaryCoverageLimitMileage = sr.PrimaryCoverageLimitMileage;
            serviceEligibiltyModel.PrimaryServiceCoverageDescription = sr.PrimaryServiceCoverageDescription;
            serviceEligibiltyModel.PrimaryServiceEligiblityMessage = sr.PrimaryServiceEligiblityMessage;

            serviceEligibiltyModel.IsServiceGuaranteed = sr.IsServiceGuaranteed;
            serviceEligibiltyModel.IsReimbursementOnly = sr.IsReimbursementOnly;
            serviceEligibiltyModel.IsServiceCoverageBestValue = sr.IsServiceCoverageBestValue;
            serviceEligibiltyModel.ProgramServiceEventLimitID = sr.ProgramServiceEventLimitID;

            serviceEligibiltyModel.CurrencyTypeID = sr.CurrencyTypeID;

            serviceEligibiltyModel.MileageUOM = sr.MileageUOM;

            serviceEligibiltyModel.IsPrimaryOverallCovered = sr.IsPrimaryOverallCovered;
            serviceEligibiltyModel.IsSecondaryOverallCovered = sr.IsSecondaryOverallCovered;

            ViewData["ServiceEligibilityModel"] = serviceEligibiltyModel;

            //TFS:163
            logger.Info("ServiceController - Index - Applying Tab Validation Status");
            SetTabValidationStatus(RequestArea.SERVICE);

            //#region Retrieve Additional Member Products Details
            //MemberManagementFacade memberFacade = new MemberManagementFacade();
            //List<MemberProductsUsingCategory_Result> memberProductsList = memberFacade.GetMemberProducts(DMSCallContext.MemberID, DMSCallContext.ProductCategoryID);
            //ViewData["MemberProductsUsingCategory_Result"] = memberProductsList;
            //#endregion
            logger.Info("ServiceController - Index - Completed");
            return PartialView("_Index", serviceTabs);
        }

        /// <summary>
        /// Gets the service limits.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetServiceLimits(int? programId, int? vehicleCategoryId)
        {
            logger.InfoFormat("ServiceController - _GetServiceLimits Started - For Program ID {0}, Vehicle Category ID {1}", programId, vehicleCategoryId);
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (programId != null && vehicleCategoryId != null)
            {
                ServiceFacade facade = new ServiceFacade();
                List<ServiceLimits_Result> data = facade.GetServiceLimits(programId.Value, vehicleCategoryId.Value);
                result.Data = data;
            }
            logger.Info("ServiceController - _GetServiceLimits - Completed");
            return Json(result);
        }

        /// <summary>
        /// Gets the questions for vehicle category.
        /// </summary>
        /// <param name="vehicleCategoryId">The vehicle category id.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetQuestionsForVehicleCategory(int? vehicleCategoryId)
        {
            var facade = new ServiceFacade();
            int programId = DMSCallContext.ProgramID;
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            logger.InfoFormat("ServiceController - _GetQuestionsForVehicleCategory Started - For Program ID {0}, Vehicle Type ID {1}, Vehicle Category ID {2}", programId, vehicleTypeId, vehicleCategoryId);
            List<ServiceTab> serviceTabs = facade.GetQuestionnaire(programId, vehicleCategoryId, vehicleTypeId, DMSCallContext.ServiceRequestID, DMSCallContext.SourceSystemFromCase);
            logger.Info("ServiceController - _GetQuestionsForVehicleCategory Completed");
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS, Data = serviceTabs };
            return Json(result);
        }

        /// <summary>
        /// Service Tech Call Log Pop Up
        /// </summary>
        /// <returns></returns>
        public ActionResult _ServiceTechCallLog(CallLogDataModel model)
        {
            logger.Info("_ServiceTechCallLog Started");

            const string category = "ContactServiceLocation";

            logger.InfoFormat("_ServiceTechCallLog Retrieving Contact Action by Category {0}", category);
            var actions = ReferenceDataRepository.GetContactAction(category);
            ViewData[StaticData.ContactActions.ToString()] = actions.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            logger.InfoFormat("_ServiceTechCallLog Retrieving Contact Reason by Category {0}", category);

            var reasons = ReferenceDataRepository.GetContactReasons(category);
            ViewData[StaticData.ContactReasons.ToString()] = reasons.ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            logger.Info("_ServiceTechCallLog Completed");
            return PartialView(model);
        }

        [HttpPost]
        public ActionResult SaveServiceTechCallLog(CallLog model)
        {
            logger.Info("Service Controller SaveServiceTechCallLog Post Started");
            logger.InfoFormat("Service Controller SaveServiceTechCallLog for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            CallLogFacade.LogServiceTechCall(model, DMSCallContext.ServiceRequestID, LoggedInUserName);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Service Controller SaveServiceTechCallLog Post Completed");
            return Json(result);
        }

        /// <summary>
        /// Saves the specified form data.
        /// </summary>
        /// <param name="formData">The form data.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        public ActionResult Save(List<NameValuePair> formData)
        {
            logger.Info("ServiceController - Save - Started");
            if (formData != null)
            {
                int serviceRequestID = DMSCallContext.ServiceRequestID;
                ServiceFacade facade = new ServiceFacade();
                logger.InfoFormat("Saving Details for Service Request ID {0} and Vehcile Type ID {1}", serviceRequestID, DMSCallContext.VehicleTypeID);
                facade.Save(formData, GetLoggedInUser().UserName, serviceRequestID, DMSCallContext.VehicleTypeID);
                logger.Info("Saved Successfully");

            }
            else
            {
                logger.Info("ServiceController - Save - Completed, no form data supplied");
            }
            return Content("");
        }

        /// <summary>
        /// Gets the diagnostic codes for service request.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetDiagnosticCodesForServiceRequest()
        {
            var serviceRepository = new ServiceRepository();
            logger.InfoFormat("ServiceController - GetDiagnosticCodesForServiceRequest - Started for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID);
            logger.Info("ServiceController - GetDiagnosticCodesForServiceRequest - Completed");
            return PartialView("_ServiceRequestDiagnosticCodes", model);
        }

        /// <summary>
        /// Updates the service tab.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="isSMSAvailable">The is SMS available.</param>
        /// <param name="productCategoryName">Name of the product category.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        public ActionResult UpdateServiceTab(ServiceRequest model, bool? isSMSAvailable, string productCategoryName)
        {
            logger.InfoFormat("ServiceController - UpdateServiceTab - Parameters : {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestID = DMSCallContext.ServiceRequestID,
                ServiceRequest = model,
                isSMSAvailable = isSMSAvailable,
                productCategoryName = productCategoryName

            }));

            OperationResult result = new OperationResult();
            ServiceFacade facade = new ServiceFacade();

            model.ID = DMSCallContext.ServiceRequestID;
            model.CaseID = DMSCallContext.CaseID;
            int? secondaryCategoryID = null;

            logger.InfoFormat("ServiceController - UpdateServiceTab - Applying Secondary Category ID by Checking IsPossibleTow {0}", model.IsPossibleTow.GetValueOrDefault());
            if (model.IsPossibleTow.GetValueOrDefault())
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    secondaryCategoryID = pc.ID;
                }
            }

            logger.InfoFormat("ServiceController - UpdateServiceTab - Performing Save with VehicleTypeID {0} Program ID {1}  IsSMSAvailable {2} SecondaryCategoryID {3} MemberID {4} PrimaryProductID {5} CaseID {6}", DMSCallContext.VehicleTypeID, DMSCallContext.ProgramID, DMSCallContext.IsSMSAvailable, secondaryCategoryID, DMSCallContext.MemberID, DMSCallContext.PrimaryProductID, DMSCallContext.CaseID);
            facade.UpdateServiceRequest(model, LoggedInUserName, DMSCallContext.VehicleTypeID, DMSCallContext.ProgramID, DMSCallContext.IsSMSAvailable, secondaryCategoryID, DMSCallContext.MemberID, DMSCallContext.PrimaryProductID, DMSCallContext.CaseID);

            // Set the values to session.
            if (DMSCallContext.ProductCategoryID != model.ProductCategoryID)
            {
                DMSCallContext.ProductCategoryID = model.ProductCategoryID;
                // Clear the cached ISPs so that it gets recalculated in Dispatch tab
                logger.Info("Resetting ISPs list");
                DMSCallContext.ISPs = null;
                DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;
                RecalculateEstimate();
            }

            DMSCallContext.IsPossibleTow = model.IsPossibleTow ?? false;
            //DMSCallContext.MemberPaymentTypeID = model.MemberPaymentTypeID;
            DMSCallContext.VehicleCategoryID = model.VehicleCategoryID;
            DMSCallContext.ProductCategoryName = productCategoryName;

            // CR : For Trigger reload of ISP list on Dispatch after primary product changes 
            ServiceRequest sr = facade.GetServiceRequestById(DMSCallContext.ServiceRequestID);
            if (sr != null)
            {
                if (DMSCallContext.PrimaryProductID != sr.PrimaryProductID || DMSCallContext.SecondaryProductID != sr.SecondaryProductID)
                {
                    DMSCallContext.PrimaryProductID = sr.PrimaryProductID;
                    DMSCallContext.SecondaryProductID = sr.SecondaryProductID;
                    logger.Info("Resetting ISPs list");
                    DMSCallContext.ISPs = null;
                    DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;
                }
            }
            result.Data = new { TabValidationStatus = (int)CallFacade.GetTabValidationStatus(DMSCallContext.ServiceRequestID, RequestArea.SERVICE) };
            logger.Info("ServiceController - UpdateServiceTab - Completed");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the diagnostic codes.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetDiagnosticCodes()
        {
            logger.Info("ServiceController - GetDiagnosticCodes - Started");

            var serviceRepository = new ServiceRepository();
            ViewData[StaticData.CodeTypes.ToString()] = serviceRepository.GetCodeTypes().ToSelectListItem(x => x.Key, y => y.Value);
            string codeType = DMSCallContext.ClientName;
            if (DMSCallContext.ClientName == "Ford")
            {
                codeType = "Ford Standard";
            }
            else
            {
                codeType = "Standard";
            }

            logger.InfoFormat("ServiceController - GetDiagnosticCodes - Retrieving Diagnostic Codes for Service Request ID {0} VehicleTypeID {1} Code Type {2}", DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            var primaryCodes = (from n in model
                                where n.IsPrimary == true
                                select n).ToList<DiagnosticCodes_Result>();
            ViewData[StaticData.PrimaryCodes.ToString()] = primaryCodes.ToSelectListItem(x => x.CodeName, y => y.CodeName, true);
            ViewData["EnableCodeTypes"] = codeType.Equals("Ford Standard");

            logger.Info("ServiceController - GetDiagnosticCodes - Completed");
            return PartialView("_DiagnosticCodes", model);
        }

        /// <summary>
        /// Gets the diagnostic code.
        /// </summary>
        /// <param name="codeType">Type of the code.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetDiagnosticCode(string codeType)
        {
            logger.Info("ServiceController - GetDiagnosticCode - Started");
            var serviceRepository = new ServiceRepository();
            logger.InfoFormat("ServiceController - GetDiagnosticCode - Retrieving Diagnostic Codes for Service Request ID {0} VehicleTypeID {1} Code Type {2}", DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            logger.Info("ServiceController - GetDiagnosticCode - Completed");
            return PartialView("_DiagnosticCodeCheckboxes", model);
        }

        /// <summary>
        /// Saves the tech comments.
        /// </summary>
        /// <param name="commentText">The comment text.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveTechComments(string commentText)
        {
            logger.Info("ServiceController - SaveTechComments - Started");
            var serviceFacade = new ServiceFacade();
            CommentFacade facade = new CommentFacade();
            var currentUser = LoggedInUserName;
            if (!string.IsNullOrEmpty(commentText))
            {
                logger.InfoFormat("ServiceController - SaveTechComments - For Service Request ID {0}, Comments {1}", DMSCallContext.ServiceRequestID, commentText);
                facade.Save(null, EntityNames.SERVICE_REQUEST, DMSCallContext.ServiceRequestID, commentText, currentUser);
                DMSCallContext.ServiceTechComments = string.Empty;
            }
            logger.Info("ServiceController - SaveTechComments - Completed");
            return PartialView("_PreviousComments", serviceFacade.GetServiceTechDetails(DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, DMSCallContext.ProgramID));
        }

        /// <summary>
        /// Saves the tech comments in session.
        /// </summary>
        /// <param name="commentText">The comment text.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveTechCommentsInSession(string commentText)
        {
            logger.Info("ServiceController - SaveTechCommentsInSession - Started");
            if (!string.IsNullOrEmpty(commentText))
            {
                DMSCallContext.ServiceTechComments = commentText;
                logger.Info("ServiceController - SaveTechCommentsInSession - Saved in Session");
            }
            logger.Info("ServiceController - SaveTechCommentsInSession - Completed");
            return Content("");
        }

        /// <summary>
        /// Gets the vehicle make.
        /// </summary>
        /// <param name="Year">The year.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <returns></returns>
        public List<SelectListItem> GetVehicleMake(string Year, int vehicleTypeID)
        {
            logger.Info("ServiceController - GetVehicleMake - Started");
            double year;
            double.TryParse(Year, out year);
            List<SelectListItem> list = null;
            logger.InfoFormat("ServiceController - GetVehicleMake - Year {0} VehicleTypeID {1}", year, vehicleTypeID);
            logger.InfoFormat("Retrieving Combo Vehicle Make for given Vehicle Year {0}", year);
            GenericIEqualityComparer<MakeModel> makeDistinct = new GenericIEqualityComparer<MakeModel>(
                (x, y) =>
                {
                    return x.Make.Equals(y.Make);
                },
                (a) =>
                {
                    return a.Make.GetHashCode();
                }
                );

            list = ReferenceDataRepository.GetVehicleMake(vehicleTypeID).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
            logger.Info("Retrieving Finished for Combo Vehicle Make");
            //switch (vehicleTypeID)
            //{
            //    case 1: // RV
            //        logger.InfoFormat("Retrieving Combo Vehicle Make for given Vehicle Year {0}", year);
            //        GenericIEqualityComparer<VehicleMakeModel> makeDistinct = new GenericIEqualityComparer<VehicleMakeModel>(
            //            (x, y) =>
            //            {
            //                return x.Make.Equals(y.Make);
            //            },
            //            (a) =>
            //            {
            //                return a.Make.GetHashCode();
            //            }
            //            );

            //        list = ReferenceDataRepository.GetVehicleMake(year).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
            //        logger.Info("Retrieving Finished for Combo Vehicle Make");
            //        break;
            //    case 2: // RV
            //        GenericIEqualityComparer<RVMakeModel> makeDistinctForRv = new GenericIEqualityComparer<RVMakeModel>(
            //            (x, y) =>
            //            {
            //                return x.Make.Equals(y.Make);
            //            },
            //            (a) =>
            //            {
            //                return a.Make.GetHashCode();
            //            }
            //            );

            //        list = ReferenceDataRepository.GetRVMake().Distinct(makeDistinctForRv).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
            //        break;
            //    case 3: // MotorCycle
            //        GenericIEqualityComparer<MotorcycleMakeModel> mcMakeDistinct = new GenericIEqualityComparer<MotorcycleMakeModel>(
            //                   (x, y) =>
            //                   {
            //                       return x.Make.Trim() == y.Model.Trim();
            //                   },
            //                   (a) =>
            //                   {
            //                       return a.Make.Trim().GetHashCode();
            //                   }
            //                   );

            //        list = ReferenceDataRepository.GetMotorcycleMake().Distinct(mcMakeDistinct).OrderBy(a => a.Make).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
            //        break;
            //    case 4: // Trailer
            //        GenericIEqualityComparer<TrailerMakeModel> makeDistinctForTrailer = new GenericIEqualityComparer<TrailerMakeModel>(
            //            (x, y) =>
            //            {
            //                return x.Make.Equals(y.Make);
            //            },
            //            (a) =>
            //            {
            //                return a.Make.GetHashCode();
            //            }
            //            );

            //        list = ReferenceDataRepository.GetTrailerMake().Distinct(makeDistinctForTrailer).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
            //        break;
            //    default:
            //        list = new List<SelectListItem>();
            //        list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            //        break;

            //}
            logger.Info("ServiceController - GetVehicleMake - Completed");
            return list;
        }

        /// <summary>
        /// _s the service auto tab.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]

        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [ReferenceDataFilter(StaticData.WarrantyPeriodUOM, false)]
        [NoCache]
        public ActionResult _ServiceAutoTab()
        {
            logger.Info("ServiceController - _ServiceAutoTab - Started");
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);

            #region Dummy Drop Down Values
            List<SelectListItem> voidYearlist = new List<SelectListItem>();
            voidYearlist.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            ViewData[StaticData.VehicleModelYear.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleMake.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleModel.ToString()] = voidYearlist;
            #endregion

            GenericIEqualityComparer<VehicleMakeModel> yearDistinct = new GenericIEqualityComparer<VehicleMakeModel>(
                       (x, y) =>
                       {
                           return x.Year.GetValueOrDefault().Equals(y.Year.GetValueOrDefault());
                       },
                       (a) =>
                       {
                           return a.Year.GetValueOrDefault().GetHashCode();
                       }
                       );

            ViewData[StaticData.VehicleModelYear.ToString()] = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), false);
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories("Auto").ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.VehicleModel.ToString()] = GetRVModelValues(string.Empty);
            Vehicle vehicle = new Vehicle();
            CaseRepository repository = new CaseRepository();
            logger.InfoFormat("ServiceController - Retrieving VehicleInformation for Case ID {0}", DMSCallContext.CaseID);
            vehicle = repository.GetVehicleInformation(DMSCallContext.CaseID);
            // KB: Bind Make values
            if (vehicle != null && vehicle.VehicleTypeID.HasValue)
            {
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicle.Year, vehicle.VehicleTypeID.Value);
            }

            VehicleFacade facade = new VehicleFacade();

            logger.InfoFormat("ServiceController - Checking ShowCommercialVehicle or not : Program ID : {0} Type : Vehicle Key : ShowCommercialVehicle", DMSCallContext.ProgramID);
            ViewBag.ShowCommercialVehicle = facade.IsShowCommercialVehicleAllowed(DMSCallContext.ProgramID, "Vehicle", "ShowCommercialVehicle");
            logger.InfoFormat("ServiceController - Checking ShowCommercialVehicle Result : {0}", ViewBag.ShowCommercialVehicle);

            if (vehicle != null && !string.IsNullOrEmpty(vehicle.LicenseState) && vehicle.VehicleLicenseCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(vehicle.VehicleLicenseCountryID.GetValueOrDefault()).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            logger.Info("ServiceController - _ServiceAutoTab - Completed");
            return PartialView(vehicle);
        }

        /// <summary>
        /// _s the service RV tab.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]
        [ReferenceDataFilter(StaticData.HitchType, true)]
        [ReferenceDataFilter(StaticData.BallSize, true)]
        [ReferenceDataFilter(StaticData.Axles, true)]
        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [ReferenceDataFilter(StaticData.WarrantyPeriodUOM, false)]
        [NoCache]
        public ActionResult _ServiceRVTab()
        {
            logger.Info("ServiceController - _ServiceRVTab - Started");
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            ViewData[StaticData.VehicleModelYear.ToString()] = GetRVYears();
            ViewData[StaticData.VehicleMake.ToString()] = GetRVMakeValues();
            var rvTypeList = ReferenceDataRepository.GetRVType(string.Empty, string.Empty);
            ViewData[StaticData.RVType.ToString()] = rvTypeList.ToSelectListItem(x => x.ID.ToString(), y => y.Name);

            var rvImageList = (from n in rvTypeList
                               select new
                               {
                                   ID = n.ID,
                                   ImageFile = n.ImageFile
                               }).ToList();

            JavaScriptSerializer ser = new JavaScriptSerializer();
            ViewData["RVImages"] = ser.Serialize(rvImageList);

            ViewData[StaticData.VehicleModel.ToString()] = GetRVModelValues(string.Empty);
            ViewData[StaticData.RVType.ToString()] = GetRVTypeValues(string.Empty, string.Empty);
            Vehicle vehicle = new Vehicle();
            CaseRepository repository = new CaseRepository();
            logger.InfoFormat("ServiceController - _ServiceRVTab - Retrieving VehicleInformation for Case ID {0}", DMSCallContext.CaseID);
            vehicle = repository.GetVehicleInformation(DMSCallContext.CaseID);
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories("RV").ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            if (vehicle != null && !string.IsNullOrEmpty(vehicle.LicenseState) && vehicle.VehicleLicenseCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(vehicle.VehicleLicenseCountryID.GetValueOrDefault()).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            logger.Info("ServiceController - _ServiceRVTab - Completed");
            return PartialView(vehicle);
        }

        /// <summary>
        /// Saves the diagnostic codes.
        /// </summary>
        /// <param name="selectedCodes">The selected codes.</param>
        /// <param name="codeType">Type of the code.</param>
        /// <param name="primaryCode">The primary code.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveDiagnosticCodes(string selectedCodes, string codeType, int? primaryCode = 0)
        {
            logger.Info("ServiceController - SaveDiagnosticCodes - Started");
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var currentUser = LoggedInUserName;
            var facade = new ServiceFacade();
            logger.InfoFormat("ServiceController - Saving with Service Request ID : {0}, Selected Codes {1} CodeType : {2}, PrimaryCode : {3}", DMSCallContext.ServiceRequestID, selectedCodes, codeType, primaryCode);
            facade.SaveDiagnosticCodes(DMSCallContext.ServiceRequestID, selectedCodes, codeType, primaryCode, currentUser);
            logger.Info("ServiceController - SaveDiagnosticCodes - Completed");
            return Json(result);
        }

        /// <summary>
        /// Gets the service eligibility.
        /// </summary>
        /// <param name="serviceTypeId">The service type identifier.</param>
        /// <param name="vehicleCategoryId">The vehicle category identifier.</param>
        /// <param name="isPossibleTow">The is possible tow.</param>
        /// <returns></returns>
        public ActionResult _GetServiceEligibility(int? serviceTypeId, int? vehicleCategoryId, bool? isPossibleTow)
        {
            logger.Info("ServiceController - _GetServiceEligibility - Started");
            OperationResult result = new OperationResult();
            ServiceFacade facade = new ServiceFacade();
            POFacade poFacade = new POFacade();
            int? secondaryCategoryID = null;
            if (isPossibleTow.GetValueOrDefault())
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    secondaryCategoryID = pc.ID;
                }
            }
            logger.InfoFormat("ServiceController - Retrieving GetServiceEligibilityModel for ProgramID : {0}, ServiceTypeID : {1}, VehicleTypeID : {2}, VehicleCategoryID {3}, SecondaryCategoryID {4}, ServiceRequestID {5}, CaseID {6}", DMSCallContext.ProgramID, serviceTypeId, DMSCallContext.VehicleTypeID, vehicleCategoryId, secondaryCategoryID, DMSCallContext.ServiceRequestID, DMSCallContext.CaseID);
            var serviceEligibilityModel = facade.GetServiceEligibilityModel(DMSCallContext.ProgramID, serviceTypeId, null, DMSCallContext.VehicleTypeID, vehicleCategoryId, secondaryCategoryID, DMSCallContext.ServiceRequestID, DMSCallContext.CaseID, SourceSystemName.DISPATCH);
            result.Data = serviceEligibilityModel;
            logger.Info("ServiceController - _GetServiceEligibility - Completed");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult _ServiceTechCallHistory()
        {
            logger.InfoFormat("MapController - _ServiceTechCallHistory()");
            logger.InfoFormat("Trying to retrieve Service Tech Call History for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            ServiceFacade facade = new ServiceFacade();
            return PartialView(facade.ServiceTechCallHistory(DMSCallContext.ServiceRequestID));
        }
        #endregion

        #region Private and Protected Methods
        /// <summary>
        /// Gets the RV model values.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <returns></returns>
        private static IEnumerable<SelectListItem> GetRVModelValues(string make)
        {
            GenericIEqualityComparer<MakeModel> modelDistinct = new GenericIEqualityComparer<MakeModel>(
                       (x, y) =>
                       {
                           return x.Model.Trim() == y.Model.Trim();
                       },
                       (a) =>
                       {
                           return a.Model.Trim().GetHashCode();
                       }
                       );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModel((int)VehicleTypes.RV,make).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Model.ToString());
            return list;
        }



        /// <summary>
        /// Gets the RV years.
        /// </summary>
        /// <returns></returns>
        protected IEnumerable<SelectListItem> GetRVYears()
        {
            List<SelectListItem> years = new List<SelectListItem>();
            int currentYear = DateTime.Now.Year + 1;
            string sYear = string.Empty;
            for (int i = 0; i <= 60; i++)
            {
                sYear = currentYear.ToString();
                years.Add(new SelectListItem() { Text = sYear, Value = sYear });
                currentYear -= 1;
            }

            return years;
        }

        /// <summary>
        /// Gets the RV make values.
        /// </summary>
        /// <returns></returns>
        private static IEnumerable<SelectListItem> GetRVMakeValues()
        {
            GenericIEqualityComparer<MakeModel> makeDistinct = new GenericIEqualityComparer<MakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleMake((int)VehicleTypes.RV).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            return list;
        }

        /// <summary>
        /// Gets the RV type values.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        private static IEnumerable<SelectListItem> GetRVTypeValues(string make, string model)
        {
            var list = ReferenceDataRepository.GetRVType(make, model).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            return list;
        }
        #endregion

    }
}
