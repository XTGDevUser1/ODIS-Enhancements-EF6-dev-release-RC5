using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using System.Collections.Specialized;
using Martex.DMS.BLL.Model;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.ActionFilters;
using Martex.DMS.DAO;
using ClientPortal.Common;
using ClientPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using ClientPortal.Areas.Application.Models;
using System.Web.Script.Serialization;
using Martex.DMS.DAL.DAO;
using System.Text;

namespace ClientPortal.Areas.Application.Controllers
{
    public class ServiceController : BaseController
    {
        #region Private Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="message"></param>
        /// <param name="eventName"></param>
        private void SaveEventDetails(string message, string eventName)
        {
            //TODO: Replace the following with EventLoggerFacade.
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            eventLoggerFacade.LogEvent(Request.RawUrl, eventName, eventName, GetLoggedInUser().UserName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            logger.Info("Created Event Log and link records");
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [ReferenceDataFilter(StaticData.ServiceMemberPayMode, true)]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_SERVICE)]
        public ActionResult Index()
        {
            var facade = new ServiceFacade();

            int programId = DMSCallContext.ProgramID;
            int? vehicleCategoryId = DMSCallContext.VehicleCategoryID;
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            SaveEventDetails("Enter Service Tab", EventNames.ENTER_SERVICE_TAB);
            List<ServiceTab> serviceTabs = facade.GetQuestionnaire(programId, vehicleCategoryId, vehicleTypeId, DMSCallContext.ServiceRequestID);
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            // JSONify Questions.
            JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
            StringBuilder jsonQuestions = new StringBuilder();
            jsonSerializer.Serialize(serviceTabs, jsonQuestions);
            ViewData["JSON_MODEL"] = jsonQuestions.ToString();

            // Get comments to be able to present them on the tech tab.
            ViewData[StringConstants.SERVICE_TECH_COMMENT] = DMSCallContext.ServiceTechComments;
            ViewData[StringConstants.SERVICE_TECH_MODEL] = facade.GetServiceTechDetails(DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);
            ViewData["VehicleTypeId"] = DMSCallContext.VehicleTypeID;
            return PartialView("_Index", serviceTabs);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="programId"></param>
        /// <param name="vehicleCategoryId"></param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetServiceLimits(int? programId, int? vehicleCategoryId)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (programId != null && vehicleCategoryId != null)
            {
                ServiceFacade facade = new ServiceFacade();
                List<ServiceLimits_Result> data = facade.GetServiceLimits(programId.Value, vehicleCategoryId.Value);
                result.Data = data;
            }

            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="vehicleCategoryId"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetQuestionsForVehicleCategory(int? vehicleCategoryId)
        {
            var facade = new ServiceFacade();

            int programId = DMSCallContext.ProgramID;
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            List<ServiceTab> serviceTabs = facade.GetQuestionnaire(programId, vehicleCategoryId, vehicleTypeId, DMSCallContext.ServiceRequestID);
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS, Data = serviceTabs };
            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="formData"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        public ActionResult Save(List<NameValuePair> formData)
        {
            if (formData != null)
            {
                logger.Info("Inside Save() of Service Controller.");

                int serviceRequestID = DMSCallContext.ServiceRequestID;
                ServiceFacade facade = new ServiceFacade();
                facade.Save(formData, GetLoggedInUser().UserName, serviceRequestID,DMSCallContext.VehicleTypeID);
                logger.Info("Finished Saveing data of Service Controller.");
                SaveEventDetails("Leave Service Tab", EventNames.LEAVE_SERVICE_TAB);
            }
            else
            {
                logger.Info("Inside Save() of Service Controller, no form data supplied");
            }

            return Content("");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetDiagnosticCodesForServiceRequest()
        {
            var serviceRepository = new ServiceRepository();
            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID);

            return PartialView("_ServiceRequestDiagnosticCodes", model);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="isSMSAvailable"></param>
        /// <param name="productCategoryName"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        public ActionResult UpdateServiceTab(ServiceRequest model, bool? isSMSAvailable, string productCategoryName)
        {
            logger.InfoFormat("Inside UpdateServiceTab() of Service Controller for {0}", DMSCallContext.ServiceRequestID);

            logger.InfoFormat("Product category name : {0}", productCategoryName);

            DMSCallContext.IsSMSAvailable = isSMSAvailable ?? false;
            model.ID = DMSCallContext.ServiceRequestID;
            model.CaseID = DMSCallContext.CaseID;

            ServiceFacade facade = new ServiceFacade();

            facade.UpdateServiceRequest(model, LoggedInUserName, DMSCallContext.VehicleTypeID, DMSCallContext.ProgramID, DMSCallContext.IsSMSAvailable);

            // Set the values to session.
            if(DMSCallContext.ProductCategoryID != model.ProductCategoryID)
            {
                DMSCallContext.ProductCategoryID = model.ProductCategoryID;
                // Clear the cached ISPs so that it gets recalculated in Dispatch tab
                logger.Info("Resetting ISPs list");
                DMSCallContext.ISPs = null;
                DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;
            }

            DMSCallContext.IsPossibleTow = model.IsPossibleTow ?? false;
            DMSCallContext.MemberPaymentTypeID = model.MemberPaymentTypeID;
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
            logger.Info("Finished updating Service Controller.");
            return Content("");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetDiagnosticCodes()
        {
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

            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            var primaryCodes = (from n in model
                                where n.IsPrimary == true
                                select n).ToList<DiagnosticCodes_Result>();
            ViewData[StaticData.PrimaryCodes.ToString()] = primaryCodes.ToSelectListItem(x => x.CodeName, y => y.CodeName, true);
            ViewData["EnableCodeTypes"] = codeType.Equals("Ford Standard");
            return PartialView("_DiagnosticCodes", model);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="codeType"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetDiagnosticCode(string codeType)
        {
            var serviceRepository = new ServiceRepository();

            var model = serviceRepository.GetDiagnosticCodes(DMSCallContext.ServiceRequestID, DMSCallContext.VehicleTypeID.GetValueOrDefault(), codeType);
            return PartialView("_DiagnosticCodeCheckboxes", model);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="currentCommentID"></param>
        /// <param name="commentText"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveTechComments(string commentText)
        {
            var serviceFacade = new ServiceFacade();

            CommentFacade facade = new CommentFacade();
            var currentUser = LoggedInUserName;
            if (!string.IsNullOrEmpty(commentText))
            {

                facade.Save(null, EntityNames.SERVICE_REQUEST, DMSCallContext.ServiceRequestID, commentText, currentUser);
                DMSCallContext.ServiceTechComments = string.Empty;
            }
            return PartialView("_PreviousComments", serviceFacade.GetServiceTechDetails(DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST));
        }

        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveTechCommentsInSession(string commentText)
        {
            if (!string.IsNullOrEmpty(commentText))
            {
                DMSCallContext.ServiceTechComments = commentText;
            }
            return Content("");
        }

        public List<SelectListItem> GetVehicleMake(string Year, int vehicleTypeID)
        {
            double year;
            double.TryParse(Year, out year);
            List<SelectListItem> list = null;
            switch (vehicleTypeID)
            {
                case 1: // RV
                    logger.InfoFormat("Retrieving Combo Vehicle Make for given Vehicle Year {0}", year);
                    GenericIEqualityComparer<VehicleMakeModel> makeDistinct = new GenericIEqualityComparer<VehicleMakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

                    list = ReferenceDataRepository.GetVehicleMake(year).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
                    logger.Info("Retrieving Finished for Combo Vehicle Make");
                    break;
                case 2: // RV
                    GenericIEqualityComparer<RVMakeModel> makeDistinctForRv = new GenericIEqualityComparer<RVMakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

                    list = ReferenceDataRepository.GetRVMake().Distinct(makeDistinctForRv).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
                    break;
                case 3: // MotorCycle
                    GenericIEqualityComparer<MotorcycleMakeModel> mcMakeDistinct = new GenericIEqualityComparer<MotorcycleMakeModel>(
                               (x, y) =>
                               {
                                   return x.Make.Trim() == y.Model.Trim();
                               },
                               (a) =>
                               {
                                   return a.Make.Trim().GetHashCode();
                               }
                               );

                    list = ReferenceDataRepository.GetMotorcycleMake().Distinct(mcMakeDistinct).OrderBy(a => a.Make).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
                    break;
                case 4: // Trailer
                    GenericIEqualityComparer<TrailerMakeModel> makeDistinctForTrailer = new GenericIEqualityComparer<TrailerMakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

                    list = ReferenceDataRepository.GetTrailerMake().Distinct(makeDistinctForTrailer).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), true).ToList();
                    break;
                default:
                    list = new List<SelectListItem>();
                    list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
                    break;

            }

            return list;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]
        [ReferenceDataFilter(StaticData.ProvinceAbbreviation, true)]
        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [NoCache]
        public ActionResult _ServiceAutoTab()
        {

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
            vehicle = repository.GetVehicleInformation(DMSCallContext.CaseID);
            // KB: Bind Make values
            if (vehicle != null && vehicle.VehicleTypeID.HasValue)
            {
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicle.Year, vehicle.VehicleTypeID.Value);
            }

            VehicleFacade facade = new VehicleFacade();  
           
            ViewBag.ShowCommercialVehicle = facade.IsShowCommercialVehicleAllowed(DMSCallContext.ProgramID, "Vehicle", "ShowCommercialVehicle");
            

            return PartialView(vehicle);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]
        [ReferenceDataFilter(StaticData.ProvinceAbbreviation, true)]
        [ReferenceDataFilter(StaticData.HitchType, true)]
        [ReferenceDataFilter(StaticData.BallSize, true)]
        [ReferenceDataFilter(StaticData.Axles, true)]
        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [NoCache]
        public ActionResult _ServiceRVTab()
        {
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
            vehicle = repository.GetVehicleInformation(DMSCallContext.CaseID);
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories("RV").ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            return PartialView(vehicle);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="selectedCodes"></param>
        /// <param name="codeType"></param>
        /// <param name="primaryCode"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveDiagnosticCodes(string selectedCodes, string codeType, int? primaryCode = 0)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var currentUser = LoggedInUserName;
            var facade = new ServiceFacade();
            facade.SaveDiagnosticCodes(DMSCallContext.ServiceRequestID, selectedCodes, codeType, primaryCode, currentUser);
            return Json(result);
        }
        #endregion

        #region Private and Protected Methods
        private static IEnumerable<SelectListItem> GetRVModelValues(string make)
        {
            GenericIEqualityComparer<RVMakeModel> modelDistinct = new GenericIEqualityComparer<RVMakeModel>(
                       (x, y) =>
                       {
                           return x.Model.Trim() == y.Model.Trim();
                       },
                       (a) =>
                       {
                           return a.Model.Trim().GetHashCode();
                       }
                       );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetRVModel(make).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Model.ToString());
            return list;
        }



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

        private static IEnumerable<SelectListItem> GetRVMakeValues()
        {
            GenericIEqualityComparer<RVMakeModel> makeDistinct = new GenericIEqualityComparer<RVMakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetRVMake().Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            return list;
        }



        private static IEnumerable<SelectListItem> GetRVTypeValues(string make, string model)
        {
            var list = ReferenceDataRepository.GetRVType(make, model).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            return list;
        }
        #endregion

    }
}
