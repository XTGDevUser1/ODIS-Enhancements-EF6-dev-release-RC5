using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using System.Text;
using System.Xml;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Controllers;
using System.Web.Script.Serialization;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    public partial class MemberController
    {
        /// <summary>
        /// Sets the membership in context.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        protected void SetMembershipInContext(int membershipID)
        {
            ViewData["MembershipID"] = membershipID;
        }

        [NoCache]
        public ActionResult _Membership_Vehicles(int membershipID)
        {
            logger.InfoFormat("Loading Membership Vehicles Tab with Membership ID {0}", membershipID);
            SetMembershipInContext(membershipID);
            
            //1. Get all vehicles for the current membership.
            List<Vehicles_Result> vehicleList = facade.GetVehiclesByMembership(membershipID);

            logger.InfoFormat("Retrieved {0} vehicles for membership {1}", vehicleList.Count, membershipID);
            VehicleTypes vehicleTypeToLoad = VehicleTypes.Auto;
            if (vehicleList.Count == 1)
            {
                ViewData["LoadVehicleIDOnLoad"] = vehicleList[0].ID;
                Enum.TryParse<VehicleTypes>(vehicleList[0].VehicleTypeID.GetValueOrDefault().ToString(),out vehicleTypeToLoad);
                ViewData["LoadVehicleTypeOnLoad"] = vehicleTypeToLoad.ToString();
            }
            else
            {
                ViewData["LoadVehicleIDOnLoad"] = -1;
            }

            // Lets put the count of vehicles by type in ViewData.
            ViewData["AutoCount"] = vehicleList.Where(x => x.VehicleTypeID == 1).Count();
            ViewData["RVCount"] = vehicleList.Where(x => x.VehicleTypeID == 2).Count();
            ViewData["MotorcycleCount"] = vehicleList.Where(x => x.VehicleTypeID == 3).Count();
            ViewData["TrailerCount"] = vehicleList.Where(x => x.VehicleTypeID == 4).Count();

            VehicleTypeModel vehicleTypeModel = GetVehicleTypeModel();
            ViewBag.ActiveProgrameVehicleType = vehicleTypeModel;


            return PartialView(vehicleList);
        }

        /// <summary>
        /// Gets the vehicle type model.
        /// </summary>
        /// <returns></returns>
        public VehicleTypeModel GetVehicleTypeModel()
        {

            VehicleTypeModel vehicleTypeModel = new VehicleTypeModel()
            {
                IsAuto = true,
                IsRV = true,
                Motorcycle = true,
                Trailer = true,
                RecordCount = 4
            };
            
            return vehicleTypeModel;
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
        [ReferenceDataFilter(StaticData.WarrantyPeriodUOM, false)]
        [NoCache]
        public ActionResult _VehicleTab(string tabName, int? id, int fromCase = 0, int? membershipID = null)
        {
            SetMembershipInContext(membershipID.GetValueOrDefault());

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
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake((int)VehicleTypes.RV);
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
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake((int)VehicleTypes.Trailer);
            }
            else if (tabName == "Motorcycle")
            {

                ViewData[StaticData.VehicleModelYear.ToString()] = GetYears();
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake((int)VehicleTypes.Motorcycle);
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

                ViewData[StaticData.VehicleModelYear.ToString()] = GetYears();//ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), false);
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake((int)VehicleTypes.Auto);
            }

            // Assign Blank Values for Vehicle Model.
            ViewData[StaticData.VehicleModel.ToString()] = GetVehicleModel(null,(int)VehicleTypes.RV);
            ViewData[StaticData.RVType.ToString()] = GetRVTypeValues(string.Empty, string.Empty);

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(tabName).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            VehicleFacade facade = new VehicleFacade();
            if (fromCase == 0)            
            {

                if (id.HasValue)
                {
                    vehicle = facade.GetVehicle(id.Value);

                }
            }
            

            VehicleTypes vehicleTypeId;
            Enum.TryParse(tabName, out vehicleTypeId);
            vehicle.VehicleTypeID = (int)vehicleTypeId;
            

            /* KB: Don't disturb the source attribute 
            if (vehicle.Source == null)
            {
                vehicle.Source = "Member Management";
            }*/


            // KB: Bind Make values
            if (vehicle != null && vehicle.VehicleTypeID.HasValue)
            {
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicle.VehicleTypeID.Value);
            }

            if (vehicle != null && !string.IsNullOrEmpty(vehicle.LicenseState) && vehicle.VehicleLicenseCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(vehicle.VehicleLicenseCountryID.GetValueOrDefault()).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
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
        /// Saves the specified vehicle.
        /// </summary>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="tabName">Name of the tab.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult SaveVehicle(Vehicle vehicle, string tabName)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            /* KB: Don't disturb the source attribute 
             * if(string.IsNullOrEmpty(vehicle.Source))
            {
                vehicle.Source = "Member Management";
            }*/
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

            logger.InfoFormat("Saving vehicle {0} for membership {1}", vehicle.ID, vehicle.MembershipID);
            facade.SaveVehiclesForMembership(vehicle,Request.RawUrl,LoggedInUserName,Session.SessionID);
            
            return Json(result);
        }

        /// <summary>
        /// Deletes the vehicle.
        /// </summary>
        /// <param name="vehicleID">The vehicle ID.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult DeleteVehicle(int? vehicleID)
        {
            OperationResult result = new OperationResult(){Status = OperationStatus.SUCCESS};
            facade.DeleteVehicle(vehicleID.GetValueOrDefault());
            return Json(result,JsonRequestBehavior.AllowGet);
        }

    }
}
