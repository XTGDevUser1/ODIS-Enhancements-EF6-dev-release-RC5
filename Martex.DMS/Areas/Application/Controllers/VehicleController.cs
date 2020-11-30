using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using System.Web.Script.Serialization;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Areas.Application.Controllers;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application
{
    /// <summary>
    /// 
    /// </summary>
    public class VehicleController : VehicleBaseController
    {
        #region Public Methods
        /// <summary>
        /// Indexes this instance
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _Index()
        {
            int memberId = DMSCallContext.MemberID;
            VehicleFacade facade = new VehicleFacade();
            List<Vehicles_Result> vehicleList = null;
            logger.InfoFormat("VehicleController - _Index() - Loading Vehicle details for Member ID : {0}", DMSCallContext.MemberID);
            //Lakshmi - Hagerty Integration -Begin

            if (DMSCallContext.HagertyIntegrationConfigFlag)
            {
                logger.InfoFormat("VehicleController - _Index() - Is the current program a Hagerty Program : {0}", DMSCallContext.IsAHagertyProgram);
                vehicleList = facade.GetMemberVehicles(memberId, DMSCallContext.MembershipID, DMSCallContext.ProgramID, Request.RawUrl, GetLoggedInUser().UserName, DMSCallContext.ServiceRequestID, HttpContext.Session.SessionID);
            }
            else
            {
                vehicleList = facade.GetMemberVehicles(memberId, DMSCallContext.MembershipID, DMSCallContext.ProgramID, Request.RawUrl, GetLoggedInUser().UserName, DMSCallContext.ServiceRequestID, HttpContext.Session.SessionID, DMSCallContext.IsAHagertyProgram);
            }

            //End


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

            //KB: Let's cache Member Home address country code.
            AddressRepository addressRepository = new AddressRepository();
            AddressEntity addressEntity = addressRepository.GetAddresses(DMSCallContext.MemberID, "Member", "Home").FirstOrDefault();
            if (addressEntity != null)
            {
                DMSCallContext.MemberHomeAddressCountryCode = addressEntity.CountryCode;
            }
            logger.InfoFormat("VehicleController - _Index() - Vehicle Count for Member ID : {0} is {1}", DMSCallContext.MemberID, vehicleList != null ? vehicleList.Count : 0);
            SetTabValidationStatus(RequestArea.VEHICLE);
            return View(vehicleList);
        }




        /// <summary>
        /// _Gets the vehicle tab.
        /// </summary>
        /// <param name="tabName">Name of the tab.</param>
        /// <param name="id">The id.</param>
        /// <param name="fromCase">From case.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Colors, true)]
        [ReferenceDataFilter(StaticData.HitchType, true)]
        [ReferenceDataFilter(StaticData.BallSize, true)]
        [ReferenceDataFilter(StaticData.Axles, true)]
        [ReferenceDataFilter(StaticData.TrailerType, true)]
        [ReferenceDataFilter(StaticData.MileageUOM, false)]
        [ReferenceDataFilter(StaticData.WarrantyPeriodUOM, true)]
        [NoCache]
        public ActionResult _VehicleTab(string tabName, int? id, int fromCase = 0)
        {
            logger.InfoFormat("VehicleController - _VehicleTab(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                tabName = tabName,
                id = id,
                fromCase = fromCase
            }));
            //logger.InfoFormat("VehicleController - _VehicleTab() - tabName : {0} ,Vehicle Id : {1}, fromCase : {2}", tabName, id.GetValueOrDefault().ToString(), fromCase);
            VehicleFacade facade = new VehicleFacade();

            #region TFS 557
            if (fromCase == 0 && id.HasValue)
            {
                CommonLookUpRepository lookUp = new CommonLookUpRepository();
                VehicleType vType = lookUp.GetVehicleTypeByName(tabName);
                if (vType == null)
                {
                    Vehicle vehicleDetails = facade.GetVehicle(id.GetValueOrDefault());
                    tabName = vehicleDetails.VehicleType.Name;
                }
            }
            #endregion


            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);

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
                ViewData[StaticData.VehicleModelYear.ToString()] = GetYears();
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
                ViewData[StaticData.VehicleModelYear.ToString()] = GetYears();
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
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake((int)VehicleTypes.Auto);

            }
            string programName = new PhoneSystemConfigurationFacade().GetProgramName(DMSCallContext.ProgramID);
            DMSCallContext.ProgramName = programName;



            if (DMSCallContext.ProgramID > 0)
            {
                // CR : 1294 : Enable / disable payment tab.
                ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                var result = programMaintenanceRepository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
                bool showDateOfPurchase = false;
                bool showFirstOwner = false;
                var DateOfPurchase = result.Where(x => (x.Name.Equals("ShowDateOfPurchase", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (DateOfPurchase != null)
                {
                    showDateOfPurchase = true;
                }
                DMSCallContext.ShowDateOfPurchase = showDateOfPurchase;
                logger.InfoFormat("Show Date Of Purchase : {0}", showDateOfPurchase);
                var FirstOwner = result.Where(x => (x.Name.Equals("ShowFirstOwner", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (FirstOwner != null)
                {
                    showFirstOwner = true;
                }
                DMSCallContext.ShowFirstOwner = showFirstOwner;
                logger.InfoFormat("Show First Owner : {0}", showFirstOwner);
            }

            // Assign Blank Values for Vehicle Model.
            ViewData[StaticData.VehicleModel.ToString()] = GetRVModelValues(string.Empty);
            ViewData[StaticData.RVType.ToString()] = GetRVTypeValues(string.Empty, string.Empty);

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(tabName).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            CaseRepository caseRepository = new CaseRepository();
            if (fromCase == 1)
            {

                if (id.HasValue)
                {
                    vehicle = caseRepository.GetVehicleInformation(id.GetValueOrDefault());
                }
                else
                {
                    vehicle = caseRepository.GetVehicleInformation(DMSCallContext.CaseID);
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
                        vehicle.VehicleLicenseCountryID = selectedVehicle.LicenseCountry;
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
            if (!string.IsNullOrEmpty(vehicle.MileageUOM))
            {
                if (DMSCallContext.MemberHomeAddressCountryCode == "US")
                {
                    vehicle.MileageUOM = "Miles";
                }
                else
                {
                    vehicle.MileageUOM = "Kilometers";
                }
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
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicle.VehicleTypeID.Value);
            }

            if (vehicle != null && !string.IsNullOrEmpty(vehicle.LicenseState) && vehicle.VehicleLicenseCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(vehicle.VehicleLicenseCountryID.GetValueOrDefault()).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }

            // TFS:228 - If Mileage is null, then use the value from [Case].
            if (vehicle.CurrentMileage == null)
            {
                var caseRecord = caseRepository.GetCaseById(DMSCallContext.CaseID);
                if (caseRecord != null)
                {
                    logger.InfoFormat("Set the mileage to {0} from Case {1}", caseRecord.VehicleCurrentMileage, caseRecord.ID);
                    vehicle.CurrentMileage = caseRecord.VehicleCurrentMileage;
                }

            }
            //TFS:278: If EndMileage is null, then use the value from WarrantyMileage.
            // TFS:331 : If EndMileage is 0, then use the value from WarrantyMileage. 
            if (vehicle.EndMileage == null || vehicle.EndMileage == 0)
            {
                int year = 0;
                int.TryParse(vehicle.Year, out year);
                var wi = GetWarrantyInformation(vehicle.VehicleTypeID.GetValueOrDefault(), year, vehicle.Make, vehicle.Model, DMSCallContext.MemberHomeAddressCountryCode);
                vehicle.EndMileage = wi.WarrantyMileage;
            }

            //TFS : 368
            if (!vehicle.WarrantyEndDate.HasValue)
            {
                if (vehicle.WarrantyPeriod.GetValueOrDefault() > 0)
                {
                    if (vehicle.WarrantyStartDate.HasValue && !string.IsNullOrEmpty(vehicle.WarrantyPeriodUOM))
                    {
                        if (vehicle.WarrantyPeriodUOM.Equals("Months", StringComparison.OrdinalIgnoreCase))
                        {
                            vehicle.WarrantyEndDate = vehicle.WarrantyStartDate.GetValueOrDefault().AddMonths(vehicle.WarrantyPeriod.GetValueOrDefault());
                        }
                        else if (vehicle.WarrantyPeriodUOM.Equals("Years", StringComparison.OrdinalIgnoreCase))
                        {
                            vehicle.WarrantyEndDate = vehicle.WarrantyStartDate.GetValueOrDefault().AddYears(vehicle.WarrantyPeriod.GetValueOrDefault());
                        }
                    }
                }
            }

            #region Rebind all the drop down with appropriate values
            ViewData[StaticData.RVType.ToString()] = ReferenceDataRepository.GetRVType(vehicle.Make, vehicle.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            ViewData[StaticData.VehicleModel.ToString()] = GetRVModelValues(vehicle.Make);
            if (!vehicle.VehicleCategoryID.HasValue)
            {
                int? defaultValue = null;
                VehicleTypes vehicleType = VehicleTypes.Auto;
                Enum.TryParse(vehicle.VehicleTypeID.GetValueOrDefault().ToString(), out vehicleType);
                if (!string.IsNullOrEmpty(vehicle.Make) && !string.IsNullOrEmpty(vehicle.Model))
                {
                    defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight((int)vehicleType, vehicle.Make, vehicle.Model);
                }
                //switch (vehicleType)
                //{
                //    case VehicleTypes.Auto:
                //        if (!string.IsNullOrEmpty(vehicle.Make) && !string.IsNullOrEmpty(vehicle.Model) && !string.IsNullOrEmpty(vehicle.Year))
                //        {
                //            defaultValue = ReferenceDataRepository.AutoDefaultWeight(vehicle.Make, vehicle.Model, vehicle.Year);
                //        }
                //        break;
                //    case VehicleTypes.RV:
                //        if (!string.IsNullOrEmpty(vehicle.Make) && !string.IsNullOrEmpty(vehicle.Model))
                //        {
                //            defaultValue = ReferenceDataRepository.RVTypeDefaultWeight(vehicle.Make, vehicle.Model, vehicle.RVTypeID.HasValue ? vehicle.RVTypeID.Value : 0);
                //        }
                //        break;
                //    case VehicleTypes.Motorcycle:
                //        if (!string.IsNullOrEmpty(vehicle.Make) && !string.IsNullOrEmpty(vehicle.Model))
                //        {
                //            defaultValue = ReferenceDataRepository.MotorcycleDefaultWeight(vehicle.Make, vehicle.Model);
                //        }
                //        break;
                //    case VehicleTypes.Trailer:
                //        if (!string.IsNullOrEmpty(vehicle.Make) && !string.IsNullOrEmpty(vehicle.Model))
                //        {
                //            defaultValue = ReferenceDataRepository.TrailerDefaultWeight(vehicle.Make, vehicle.Model);
                //        }
                //        break;
                //    default:
                //        break;
                //}
                vehicle.VehicleCategoryID = defaultValue;
            }
            #endregion

            return PartialView(partialView, vehicle);
        }

        /// <summary>
        /// On selecting the Vehicle.
        /// </summary>
        /// <param name="vehicleId">The vehicle id.</param>
        /// <param name="tabName">Name of the tab.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _OnSelect(int vehicleId, string tabName)
        {
            return PartialView(tabName);
        }

        /// <summary>
        /// Gets the max allowed vehicles.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMaxAllowedVehicles(string vehicleType)
        {
            //logger.InfoFormat("VehicleController - GetMaxAllowedVehicles() - vehicleType : {0}", vehicleType);
            VehicleTypes vehicleTypeId = VehicleTypes.Auto;
            Enum.TryParse(vehicleType, out vehicleTypeId);

            VehicleRepository repository = new VehicleRepository();
            int? maxAllowed = repository.GetMaxAllowed(DMSCallContext.ProgramID, (int)vehicleTypeId);

            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS,
                Data = maxAllowed
            };
            logger.InfoFormat("VehicleController - GetMaxAllowedVehicles(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                vehicleType = vehicleType
            }), JsonConvert.SerializeObject(new
            {
                MaxAllowedVehicles = maxAllowed
            }));
            //logger.InfoFormat("VehicleController - GetMaxAllowedVehicles for - vehicleType : {0} is : {1}", vehicleType, maxAllowed.GetValueOrDefault().ToString());
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the specified vehicle.
        /// </summary>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="tabName">Name of the tab.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult Save(Vehicle vehicle, string tabName, string mainTabName)
        {
            logger.InfoFormat("VehicleController - Save() - Parameters : {0}",JsonConvert.SerializeObject(new
            {
                tabName = tabName,
                mainTabName = mainTabName,
                ServiceRequestID = DMSCallContext.ServiceRequestID,
                Vehicle = vehicle

            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (string.IsNullOrEmpty(vehicle.Source))
            {
                vehicle.Source = "Service Request";
            }
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

            CaseFacade.UpdateVehicleInformation(DMSCallContext.CaseID, DMSCallContext.ServiceRequestID, DMSCallContext.ProgramID, vehicle, Request.RawUrl, LoggedInUserName, HttpContext.Session.SessionID, mainTabName);
            DMSCallContext.LastUpdatedVehicleType = tabName;

            // Reset ISP list when vehicle type of category is changed.
            if (DMSCallContext.VehicleTypeID != vehicle.VehicleTypeID || DMSCallContext.VehicleCategoryID != vehicle.VehicleCategoryID)
            {
                logger.Info("Reseting ISPs list due to change in vehicle attributes");
                DMSCallContext.ISPs = null;
                DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;
                RecalculateEstimate();
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
        /// Gets the vehicle type model.
        /// </summary>
        /// <param name="facade">The facade.</param>
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
        /// Gets the RV model.
        /// </summary>
        /// <param name="make">The make.</param>
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
        /// Gets the RV types.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult _GetRVTypes(string make, string model)
        {
            var list = GetRVTypeValues(make, model);
            logger.InfoFormat("VehicleController - _GetRVTypes(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model
            }), JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return Json(list, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Gets the RV make.
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
        /// Gets the combo vehicle model trailer.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="year">The year.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public JsonResult _GetComboVehicleModelTrailer(string make, double? year)
        {
            logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);

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

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModel((int)VehicleTypes.Trailer, make,true).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            logger.InfoFormat("VehicleController - _GetComboVehicleModelTrailer(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                year = year
            }), JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the motor cycle model.
        /// </summary>
        /// <param name="Make">The make.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public JsonResult _GetMotorCycleModel(string Make)
        {
            GenericIEqualityComparer<MakeModel> mcModelDistinct = new GenericIEqualityComparer<MakeModel>(
                                (x, y) =>
                                {
                                    return x.Model.Trim() == y.Model.Trim();
                                },
                                (a) =>
                                {
                                    return a.Model.Trim().GetHashCode();
                                }
                                );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModel((int)VehicleTypes.Motorcycle, Make,true).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            logger.InfoFormat("VehicleController - _GetMotorCycleModel(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                Make = Make
            }), JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the RV default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <param name="rvtypeId">The rvtype id.</param>
        /// <returns></returns>
        public JsonResult _GetRVDefaultWeight(string make, string model, int? rvtypeId)
        {
            int? defaultValue = ReferenceDataRepository.RVTypeDefaultWeight((int)VehicleTypes.RV, make, model, rvtypeId.HasValue ? rvtypeId.Value : 0);
            logger.InfoFormat("VehicleController - _GetRVDefaultWeight(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model,
                rvtypeId = rvtypeId
            }), JsonConvert.SerializeObject(new
            {
                DefaultWeight = defaultValue
            }));
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the motorcycle default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public JsonResult _GetMotorcycleDefaultWeight(string make, string model)
        {
            int? defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight((int)VehicleTypes.Motorcycle, make, model);
            logger.InfoFormat("VehicleController - _GetMotorcycleDefaultWeight(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model
            }), JsonConvert.SerializeObject(new
            {
                DefaultWeight = defaultValue
            }));
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the trailer default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public JsonResult _GetTrailerDefaultWeight(string make, string model)
        {
            int? defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight((int)VehicleTypes.Trailer, make, model);
            logger.InfoFormat("VehicleController - _GetTrailerDefaultWeight(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model
            }), JsonConvert.SerializeObject(new
            {
                DefaultWeight = defaultValue
            }));
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the auto default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public JsonResult _GetAutoDefaultWeight(string make, string model)
        {
            int defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight((int)VehicleTypes.Auto, make, model);
            //logger.InfoFormat("VehicleController - _GetAutoDefaultWeight() - make : {0} ,model : {1}, year : {2}, AutoDefaultWeight is :{3} ", make, model, year, defaultValue);
            logger.InfoFormat("VehicleController - _GetAutoDefaultWeight(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model                
            }), JsonConvert.SerializeObject(new
            {
                DefaultWeight = defaultValue
            }));
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the validation required fields.
        /// </summary>
        /// <returns></returns>
        public JsonResult _GetValidationRequiredFields()
        {
            List<ProgramInformation_Result> pr = ReferenceDataRepository.GetVehicleValidationRule(DMSCallContext.ProgramID);
            return Json(new { Data = pr }, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Gets the vehicle categories.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type unique identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult GetVehicleCategories(int vehicleTypeID)
        {
            var categories = ReferenceDataRepository.GetVehicleCategories(vehicleTypeID).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            logger.InfoFormat("VehicleController - GetVehicleCategories(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                vehicleTypeID = vehicleTypeID
            }), JsonConvert.SerializeObject(new
            {
                Categories = categories
            }));
            return Json(categories, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get the default weight.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <param name="rvtypeId">The rvtype unique identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type unique identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetDefaultWeight(string make, string model, int? rvtypeId, int vehicleTypeID)
        {
            int? defaultValue = null;
            VehicleTypes vehicleType = VehicleTypes.Auto;
            Enum.TryParse(vehicleTypeID.ToString(), out vehicleType);

            switch (vehicleType)
            {
                case VehicleTypes.Auto:
                case VehicleTypes.Motorcycle:
                case VehicleTypes.Trailer:
                    defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight((int)vehicleType, make, model);
                    break;
                case VehicleTypes.RV:
                    defaultValue = ReferenceDataRepository.RVTypeDefaultWeight((int)vehicleType, make, model, rvtypeId.HasValue ? rvtypeId.Value : 0);
                    break;
                //case VehicleTypes.Motorcycle:
                //    defaultValue = ReferenceDataRepository.MotorcycleDefaultWeight(make, model);
                //    break;
                //case VehicleTypes.Trailer:
                //    defaultValue = ReferenceDataRepository.TrailerDefaultWeight(make, model);
                //    break;
                default:
                    break;
            }
            logger.InfoFormat("VehicleController - _GetDefaultWeight(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make,
                model = model,
                rvtypeId = rvtypeId,
                vehicleTypeID = vehicleTypeID
            }), JsonConvert.SerializeObject(new
            {
                DefaultWeight = defaultValue
            }));
            return Json(new { Data = defaultValue }, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// Gets the warranty details.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type identifier.</param>
        /// <param name="year">The year.</param>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult GetWarrantyDetails(int? vehicleTypeID, int? year, string make, string model)
        {
            logger.InfoFormat("VehicleController - GetWarrantyDetails() - vehicleTypeID : {0} ,year : {1}, make : {2}, model :{3} ", vehicleTypeID, year, make, model);
            OperationResult result = new OperationResult();
            result.Data = GetWarrantyInformation(vehicleTypeID.GetValueOrDefault(), year, make, model, DMSCallContext.MemberHomeAddressCountryCode);
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        #endregion

        #region Private Methods
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

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModel((int)VehicleTypes.RV, make,true).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString()).ToList();
            logger.InfoFormat("VehicleController - GetRVModelValues(), Parameters : {0}, Returns : {1}", JsonConvert.SerializeObject(new
            {
                make = make
            }), JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return list;
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
            logger.InfoFormat("VehicleController - GetRVMakeValues(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return list;
        }

        /// <summary>
        /// Gets the trailer make values.
        /// </summary>
        /// <returns></returns>
        private static IEnumerable<SelectListItem> GetTrailerMakeValues()
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

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleMake((int)VehicleTypes.Trailer).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            logger.InfoFormat("VehicleController - GetTrailerMakeValues(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return list;
        }

        /// <summary>
        /// Gets the motor cycle make.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        private static IEnumerable<SelectListItem> GetMotorCycleMake()
        {
            GenericIEqualityComparer<MakeModel> mcMakeDistinct = new GenericIEqualityComparer<MakeModel>(
                                (x, y) =>
                                {
                                    return x.Make.Trim() == y.Model.Trim();
                                },
                                (a) =>
                                {
                                    return a.Make.Trim().GetHashCode();
                                }
                                );

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleMake((int)VehicleTypes.Motorcycle).Distinct(mcMakeDistinct).OrderBy(a => a.Make).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            logger.InfoFormat("VehicleController - GetMotorCycleMake(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                list = list
            }));
            return list;
        }
        #endregion

        #region TFS 557
        public ActionResult IsVehicleTypeExists(string tabName, int? id, int fromCase = 0)
        {
            logger.InfoFormat("VehicleController - IsVehicleTypeExists(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                tabName = tabName,
                id = id,
                fromCase = fromCase
            }));
            //logger.InfoFormat("VehicleController - IsVehicleTypeExists() - tabName : {0} ,id : {1}, fromCase : {2}", tabName, id.GetValueOrDefault().ToString(), fromCase);
            bool IsExists = true;
            JsonResult result = new JsonResult();
            if (fromCase == 0 && id.HasValue)
            {
                VehicleFacade facade = new VehicleFacade();
                Vehicle vehicle = facade.GetVehicle(id.GetValueOrDefault());
                if (!vehicle.VehicleTypeID.HasValue)
                {
                    IsExists = false;
                }
            }
            result.Data = new { IsVehicleTypeExists = IsExists.ToString().ToLower() };
            logger.InfoFormat("VehicleController - IsVehicleTypeExists for - tabName : {0} ,id : {1}, fromCase : {2} is {3} ", tabName, id.GetValueOrDefault().ToString(), fromCase, IsExists.ToString());
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult VehicleTypeSelection(string tabName, int? id, int fromCase = 0)
        {
            logger.InfoFormat("VehicleController - VehicleTypeSelection(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                tabName = tabName,
                id = id,
                fromCase = fromCase
            }));
            VehicleFacade facade = new VehicleFacade();
            Vehicle vehcileDetails = facade.GetVehicle(id.GetValueOrDefault());
            VehicleTypeModel vehicleTypeModel = GetVehicleTypeModel(facade);
            ViewBag.ActiveProgrameVehicleType = vehicleTypeModel;
            ViewBag.ShowCommercialVehicle = facade.IsShowCommercialVehicleAllowed(DMSCallContext.ProgramID, "Vehicle", "ShowCommercialVehicle");
            return PartialView(vehcileDetails);
        }

        [HttpPost]
        public ActionResult UpdateVehicleTypeDetails(int vehicleID, string VehcileTypeSelection)
        {
            logger.InfoFormat("VehicleController - UpdateVehicleTypeDetails(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                vehicleID = vehicleID,
                VehcileTypeSelection = VehcileTypeSelection
            }));
            OperationResult result = new OperationResult();
            VehicleFacade facade = new VehicleFacade();
            CommonLookUpRepository lookUp = new CommonLookUpRepository();
            Vehicle model = facade.GetVehicle(vehicleID);
            model.VehicleTypeID = lookUp.GetVehicleTypeByName(VehcileTypeSelection).ID;
            facade.UpdateVehicleTypeDetails(model, LoggedInUserName);
            return Json(result);
        }
        #endregion


    }
}
