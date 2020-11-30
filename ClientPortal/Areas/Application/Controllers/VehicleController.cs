using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.ActionFilters;
using ClientPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using ClientPortal.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using ClientPortal.Areas.Application.Models;
using ClientPortal.Areas.Common.Controllers;
using System.Web.Script.Serialization;
using Martex.DMS.DAL.DAO;
using ClientPortal.Areas.Application.Controllers;

namespace Martex.DMS.Areas.Application
{
    public class VehicleController : VehicleBaseController
    {
        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_VEHICLE)]
        public ActionResult _Index()
        {

            logger.InfoFormat("Is the current program a Hagerty Program : {0}", DMSCallContext.IsAHagertyProgram);
            int memberId = DMSCallContext.MemberID;
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ENTER_VEHICLE_TAB, "Entered vehicle tab", LoggedInUserName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            VehicleFacade facade = new VehicleFacade();

            List<Vehicles_Result> vehicleList = facade.GetMemberVehicles(memberId, DMSCallContext.MembershipID, DMSCallContext.ProgramID, Request.RawUrl, GetLoggedInUser().UserName, DMSCallContext.ServiceRequestID, HttpContext.Session.SessionID, DMSCallContext.IsAHagertyProgram);
            if (vehicleList != null && vehicleList.Count > 0 && vehicleList[0].FromCase == 2)
            {
                DMSCallContext.HagertyVehicles = vehicleList;
            }
            ViewBag.ShowCommercialVehicle = facade.IsShowCommercialVehicleAllowed(DMSCallContext.ProgramID, "Vehicle", "ShowCommercialVehicle");
            // Lets put the count of vehicles by type in ViewData.
            ViewData["AutoCount"] = vehicleList.Where(x => x.VehicleTypeID == 1).Count();
            ViewData["RVCount"] = vehicleList.Where(x => x.VehicleTypeID == 2).Count();
            ViewData["MotorcycleCount"] = vehicleList.Where(x => x.VehicleTypeID == 3).Count();
            ViewData["TrailerCount"] = vehicleList.Where(x => x.VehicleTypeID == 4).Count();

            VehicleTypeModel vehicleTypeModel = GetVehicleTypeModel(facade);
            ViewBag.ActiveProgrameVehicleType = vehicleTypeModel;
            return View(vehicleList);
        }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="tabName"></param>
        /// <param name="id"></param>
        /// <param name="fromCase"></param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]
        [ReferenceDataFilter(StaticData.ProvinceAbbreviation, true)]
        [ReferenceDataFilter(StaticData.HitchType, true)]
        [ReferenceDataFilter(StaticData.BallSize, true)]
        [ReferenceDataFilter(StaticData.Axles, true)]
        [ReferenceDataFilter(StaticData.TrailerType, true)]
        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [NoCache]
        public ActionResult _VehicleTab(string tabName, int? id, int fromCase = 0)
        {
            #region Dummy Drop Down Values
            List<SelectListItem> voidYearlist = new List<SelectListItem>();
            voidYearlist.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            ViewData[StaticData.VehicleModelYear.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleMake.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleModel.ToString()] = voidYearlist;
            #endregion

            string partialView = string.Format("_{0}Tab", tabName);
            Vehicle vehicle = new Vehicle();
            if (tabName == "RV")
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

            }
            else if (tabName == "Trailer")
            {
                ViewData[StaticData.VehicleModelYear.ToString()] = GetTrailerYears();
                ViewData[StaticData.VehicleMake.ToString()] = GetTrailerMakeValues();
            }
            else if (tabName == "Motorcycle")
            {

                ViewData[StaticData.VehicleModelYear.ToString()] = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), false);
                ViewData[StaticData.VehicleMake.ToString()] = GetMotorCycleMake();
            }
            else
            {
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

            }

            // Assign Blank Values for Vehicle Model.
            ViewData[StaticData.VehicleModel.ToString()] = GetRVModelValues(string.Empty);
            ViewData[StaticData.RVType.ToString()] = GetRVTypeValues(string.Empty, string.Empty);

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(tabName).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            VehicleFacade facade = new VehicleFacade();
            if (fromCase == 1)
            {
                CaseRepository repository = new CaseRepository();
                if (id.HasValue)
                {
                    vehicle = repository.GetVehicleInformation(id.GetValueOrDefault());
                }
                else
                {
                    vehicle = repository.GetVehicleInformation(DMSCallContext.CaseID);
                }
            }
            else if (fromCase == 2)
            {
                if (DMSCallContext.HagertyVehicles != null)
                {
                    Vehicles_Result selectedVehicle = DMSCallContext.HagertyVehicles.Where(v => v.ID == id.GetValueOrDefault()).FirstOrDefault<Vehicles_Result>();
                    if (selectedVehicle != null)
                    {
                        vehicle.Make = selectedVehicle.Make;
                        vehicle.Model = selectedVehicle.Model;
                        vehicle.Year = selectedVehicle.Year;
                        vehicle.VehicleTypeID = selectedVehicle.VehicleTypeID;
                        vehicle.VehicleCategoryID = 1;
                    }
                }
            }
            else
            {

                if (id.HasValue)
                {
                    vehicle = facade.GetVehicle(id.Value);

                }
            }
            if (tabName == "Auto")
            {
                ViewBag.ShowCommercialVehicle = facade.IsShowCommercialVehicleAllowed(DMSCallContext.ProgramID, "Vehicle", "ShowCommercialVehicle");
            }

            VehicleTypes vehicleTypeId;
            Enum.TryParse(tabName, out vehicleTypeId);
            vehicle.VehicleTypeID = (int)vehicleTypeId;
            DMSCallContext.VehicleTypeID = vehicle.VehicleTypeID;

            if (vehicle.Source == null)
            {
                vehicle.Source = "Service Request";
            }


            // KB: Bind Make values
            if (vehicle != null && vehicle.VehicleTypeID.HasValue)
            {
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicle.Year, vehicle.VehicleTypeID.Value);
            }
            return PartialView(partialView, vehicle);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="vehicleId"></param>
        /// <param name="tabName"></param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _OnSelect(int vehicleId, string tabName)
        {
            return PartialView(tabName);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="vehicleType"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMaxAllowedVehicles(string vehicleType)
        {
            VehicleTypes vehicleTypeId = VehicleTypes.Auto;
            Enum.TryParse(vehicleType, out vehicleTypeId);

            VehicleRepository repository = new VehicleRepository();
            int? maxAllowed = repository.GetMaxAllowed(DMSCallContext.ProgramID, (int)vehicleTypeId);

            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS,
                Data = maxAllowed
            };

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="vehicle"></param>
        /// <param name="tabName"></param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Save(Vehicle vehicle, string tabName)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (string.IsNullOrEmpty(vehicle.Source))
            {
                vehicle.Source = "Service Request";
            }

            // Handle placeholders

            // Handle placeholders
            if (!string.IsNullOrEmpty(vehicle.LicenseState) && vehicle.LicenseState.Equals("select", StringComparison.InvariantCultureIgnoreCase))
            {
                vehicle.LicenseState = null;
            }
            if (!string.IsNullOrEmpty(vehicle.Year) && vehicle.Year.Equals("select year", StringComparison.InvariantCultureIgnoreCase))
            {
                vehicle.Year = null;
            }
            if (!string.IsNullOrEmpty(vehicle.Make) && vehicle.Make.Equals("select make", StringComparison.InvariantCultureIgnoreCase))
            {
                vehicle.Make = null;
            }
            if (!string.IsNullOrEmpty(vehicle.Model) && vehicle.Model.Equals("select model", StringComparison.InvariantCultureIgnoreCase))
            {
                vehicle.Model = null;
            }
            CaseFacade.UpdateVehicleInformation(DMSCallContext.CaseID, DMSCallContext.ServiceRequestID, DMSCallContext.ProgramID, vehicle, Request.RawUrl, LoggedInUserName, HttpContext.Session.SessionID);
            DMSCallContext.LastUpdatedVehicleType = tabName;

            // Reset ISP list when vehicle type of category is changed.
            if (DMSCallContext.VehicleTypeID != vehicle.VehicleTypeID || DMSCallContext.VehicleCategoryID != vehicle.VehicleCategoryID)
            {
                logger.Info("Reseting ISPs list due to change in vehicle attributes");
                DMSCallContext.ISPs = null;
                DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;
            }
            // CR : 1215 : Don't set vehicle category if the value is null. This might have got set in Service tab.
            if (vehicle.VehicleCategoryID != null)
            {
                DMSCallContext.VehicleCategoryID = vehicle.VehicleCategoryID;
            }
            DMSCallContext.VehicleTypeID = vehicle.VehicleTypeID;
            DMSCallContext.VehicleMake = vehicle.Make;
            DMSCallContext.VehicleYear = vehicle.Year;
            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="facade"></param>
        /// <returns></returns>
        public VehicleTypeModel GetVehicleTypeModel(VehicleFacade facade)
        {
            int programeId = DMSCallContext.ProgramID;
            VehicleTypeModel vehicleTypeModel = new VehicleTypeModel();

            List<ProgramVehicleType> programeVehicleTypeList = facade.GetVehicleTypeByPrograme(programeId);
            vehicleTypeModel.RecordCount = programeVehicleTypeList.Count;
            foreach (ProgramVehicleType programVehicleType in programeVehicleTypeList)
            {
                switch (programVehicleType.VehicleTypeID)
                {
                    case (int)VehicleTypes.Auto:
                        {
                            vehicleTypeModel.IsAuto = true;
                            break;
                        }
                    case (int)VehicleTypes.RV:
                        {
                            vehicleTypeModel.IsRV = true;
                            break;
                        }
                    case (int)VehicleTypes.Motorcycle:
                        {
                            vehicleTypeModel.Motorcycle = true;
                            break;
                        }
                    case (int)VehicleTypes.Trailer:
                        {
                            vehicleTypeModel.Trailer = true;
                            break;
                        }
                }
            }

            return vehicleTypeModel;
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="make"></param>
        /// <returns></returns>
        [HttpPost]
        public JsonResult _GetRVModel(string make)
        {
            logger.InfoFormat("Retrieving RV models for Make {0} ", make);

            IEnumerable<SelectListItem> list = GetRVModelValues(make);
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            return Json(list, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="make"></param>
        /// <param name="model"></param>
        /// <returns></returns>
        public ActionResult _GetRVTypes(string make, string model)
        {
            var list = GetRVTypeValues(make, model);
            return Json(list, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public JsonResult _GetRVMake()
        {
            logger.Info("Retrieving RV Makes");
            IEnumerable<SelectListItem> list = GetRVMakeValues();
            logger.Info("Retrieving Finished for Combo Vehicle Make");
            return Json(list, JsonRequestBehavior.AllowGet);

        }



        /// <summary>
        /// 
        /// </summary>
        /// <param name="make"></param>
        /// <param name="year"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public JsonResult _GetComboVehicleModelTrailer(string make, double? year)
        {
            logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);

            GenericIEqualityComparer<TrailerMakeModel> modelDistinct = new GenericIEqualityComparer<TrailerMakeModel>(
                      (x, y) =>
                      {
                          return x.Model.Trim() == y.Model.Trim();
                      },
                      (a) =>
                      {
                          return a.Model.Trim().GetHashCode();
                      }
                      );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModelForTrailer(make, year.GetValueOrDefault()).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Make"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public JsonResult _GetMotorCycleModel(string Make)
        {
            GenericIEqualityComparer<MotorcycleMakeModel> mcModelDistinct = new GenericIEqualityComparer<MotorcycleMakeModel>(
                                (x, y) =>
                                {
                                    return x.Model.Trim() == y.Model.Trim();
                                },
                                (a) =>
                                {
                                    return a.Model.Trim().GetHashCode();
                                }
                                );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetMotorcycleModel(Make).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        public JsonResult _GetRVDefaultWeight(string make, string model, int? rvtypeId)
        {
            int? defaultValue = ReferenceDataRepository.RVTypeDefaultWeight(make, model, rvtypeId.HasValue ? rvtypeId.Value : 0);
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        public JsonResult _GetMotorcycleDefaultWeight(string make, string model)
        {
            int? defaultValue = ReferenceDataRepository.MotorcycleDefaultWeight(make, model);
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }
        public JsonResult _GetTrailerDefaultWeight(string make, string model)
        {
            int? defaultValue = ReferenceDataRepository.TrailerDefaultWeight(make, model);
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        public JsonResult _GetAutoDefaultWeight(string make, string model)
        {
            int defaultValue = ReferenceDataRepository.AutoDefaultWeight(make, model);
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        public JsonResult _GetValidationRequiredFields()
        {
            List<ProgramInformation_Result> pr = ReferenceDataRepository.GetVehicleValidationRule(DMSCallContext.ProgramID);
            return Json(new { Data = pr }, JsonRequestBehavior.AllowGet);
        }

        #endregion


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

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetRVModel(make).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            return list;
        }

        private static IEnumerable<SelectListItem> GetRVTypeValues(string make, string model)
        {
            var list = ReferenceDataRepository.GetRVType(make, model).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            return list;
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

        private static IEnumerable<SelectListItem> GetTrailerMakeValues()
        {
            GenericIEqualityComparer<TrailerMakeModel> makeDistinct = new GenericIEqualityComparer<TrailerMakeModel>(
                        (x, y) =>
                        {
                            return x.Make.Equals(y.Make);
                        },
                        (a) =>
                        {
                            return a.Make.GetHashCode();
                        }
                        );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetTrailerMake().Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            return list;
        }

        [HttpPost]
        [ValidateInput(false)]
        private static IEnumerable<SelectListItem> GetMotorCycleMake()
        {
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

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetMotorcycleMake().Distinct(mcMakeDistinct).OrderBy(a => a.Make).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            return list;
        }


    }
}
