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
using Martex.DMS.Areas.Application.Controllers;
using Martex.DMS.Areas.Application.Models;
using System.Web.Script.Serialization;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimController
    {
        public ClaimInformationModel InitlizeVehcileInformation(ClaimInformationModel model)
        {
            /* Initialize ViewData items with empty list */
            var emptyList = new List<SelectListItem>();

            ViewData[StaticData.VehicleModelYear.ToString()] = emptyList;
            ViewData[StaticData.VehicleMake.ToString()] = emptyList;
            ViewData[StaticData.VehicleModel.ToString()] = emptyList;
            ViewData[StaticData.VehicleCategory.ToString()] = emptyList;
            ViewData[StaticData.RVType.ToString()] = null;

            // Fill the dropdown values for Vehicle related fields.
            var claim = model.Claim;
            int? vehicleTypeID = claim.VehicleTypeID;

            ViewData[StaticData.VehicleType.ToString()] = ReferenceDataRepository.GetVehicleType(true).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            var serviceTypes = ReferenceDataRepository.GetProductCategories().Where(x => (x.Description != "Billing"
                                                                                            &&
                                                                                        x.Description != "Concierge"
                                                                                            &&
                                                                                        x.Description != "Information"
                                                                                            &&
                                                                                        x.Description != "Technician")).ToList<ProductCategory>();
            ViewData[StaticData.ServiceType.ToString()] = serviceTypes.ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            if (vehicleTypeID != null)
            {
                PrepareVehicleData(claim, vehicleTypeID);
            }

            // Special case - fill rv types
            if (ViewData[StaticData.RVType.ToString()] == null)
            {
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
            return model;
        }

        /// <summary>
        /// Prepares the vehicle data.
        /// </summary>
        /// <param name="claim">The claim.</param>
        /// <param name="vehicleTypeID">The vehicle type unique identifier.</param>
        private void PrepareVehicleData(Claim claim, int? vehicleTypeID)
        {
            ViewData[StaticData.VehicleModelYear.ToString()] = GetYears();
            VehicleTypes vehicleType = VehicleTypes.Auto;
            Enum.TryParse(vehicleTypeID.GetValueOrDefault().ToString(), out vehicleType);
            string vehicleYear = claim.VehicleYear;
            double? dVehicleYear = null;
            if (!string.IsNullOrEmpty(vehicleYear))
            {
                try
                {
                    dVehicleYear = double.Parse(vehicleYear);
                }
                catch (Exception)
                {

                }
            }
            string vehicleMake = claim.VehicleMake;
            string vehicleModel = claim.VehicleModel;
            int? rvType = claim.RVTypeID;

            ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(vehicleTypeID.GetValueOrDefault());
            ViewData[StaticData.VehicleModel.ToString()] = GetVehicleModel(vehicleMake, vehicleTypeID.GetValueOrDefault());
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeID.GetValueOrDefault()).ToSelectListItem(key => key.ID.ToString(), val => val.Name);
        }

        public ActionResult _Claims_Vehicle_Service(int claimID, int programID, string membershipNumber)
        {
            var facade = new ClaimsFacade();
            ClaimInformationModel claimModel = new ClaimInformationModel();
            claimModel.Claim = facade.GetVehicleFormembership(membershipNumber);
            var claim = claimModel.Claim;
            /* Initialize ViewData items with empty list */
            var emptyList = new List<SelectListItem>();

            ViewData[StaticData.VehicleModelYear.ToString()] = emptyList;
            ViewData[StaticData.VehicleMake.ToString()] = emptyList;
            ViewData[StaticData.VehicleModel.ToString()] = emptyList;
            ViewData[StaticData.VehicleCategory.ToString()] = emptyList;
            ViewData[StaticData.RVType.ToString()] = null;

            // Fill the dropdown values for Vehicle related fields.
            int? vehicleTypeID = claim.VehicleTypeID;

            ViewData[StaticData.VehicleType.ToString()] = ReferenceDataRepository.GetVehicleType(true).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            var serviceTypes = ReferenceDataRepository.GetProductCategories().Where(x => (x.Description != "Billing"
                                                                                            &&
                                                                                        x.Description != "Concierge"
                                                                                            &&
                                                                                        x.Description != "Information"
                                                                                            &&
                                                                                        x.Description != "Technician")).ToList<ProductCategory>();
            ViewData[StaticData.ServiceType.ToString()] = serviceTypes.ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            if (vehicleTypeID != null)
            {
                PrepareVehicleData(claim, vehicleTypeID);
            }

            // Special case - fill rv types
            if (ViewData[StaticData.RVType.ToString()] == null)
            {
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
            return PartialView(claimModel);
        }

        [HttpPost]
        public ActionResult _Vehicle(int? vehicleID, int? claimID)
        {
            VehicleFacade vehicleFacade = new VehicleFacade();
            var vehicle = vehicleFacade.GetVehicle(vehicleID.GetValueOrDefault());
            Claim claim = new Claim();
            claim.ID = claimID.GetValueOrDefault();
            if(vehicle != null)
            {
                claim.VehicleID = vehicle.ID;
                claim.VehicleTypeID = vehicle.VehicleTypeID;
                claim.RVTypeID = vehicle.RVTypeID;
                
                claim.VehicleVIN = vehicle.VIN;
                claim.VehicleYear = vehicle.Year;
                claim.VehicleMake = vehicle.Make;
                claim.VehicleMakeOther = vehicle.MakeOther;
                claim.VehicleModel = vehicle.Model;
                claim.VehicleModelOther = vehicle.ModelOther;
                claim.VehicleCategoryID = vehicle.VehicleCategoryID;
                claim.WarrantyStartDate = vehicle.WarrantyStartDate;
                claim.VehicleChassis = vehicle.Chassis;
                claim.VehicleEngine = vehicle.Engine;
                claim.VehicleTransmission = vehicle.Transmission;
                claim.CurrentMiles = vehicle.CurrentMileage;            
            }
            ClaimInformationModel claimModel = new ClaimInformationModel();
            claimModel.Claim = claim;

            /* Initialize ViewData items with empty list */
            var emptyList = new List<SelectListItem>();

            ViewData[StaticData.VehicleModelYear.ToString()] = emptyList;
            ViewData[StaticData.VehicleMake.ToString()] = emptyList;
            ViewData[StaticData.VehicleModel.ToString()] = emptyList;
            ViewData[StaticData.VehicleCategory.ToString()] = emptyList;
            ViewData[StaticData.RVType.ToString()] = null;

            // Fill the dropdown values for Vehicle related fields.
            int? vehicleTypeID = claim.VehicleTypeID;

            ViewData[StaticData.VehicleType.ToString()] = ReferenceDataRepository.GetVehicleType(true).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            var serviceTypes = ReferenceDataRepository.GetProductCategories().Where(x => (x.Description != "Billing"
                                                                                            &&
                                                                                        x.Description != "Concierge"
                                                                                            &&
                                                                                        x.Description != "Information"
                                                                                            &&
                                                                                        x.Description != "Technician")).ToList<ProductCategory>();
            ViewData[StaticData.ServiceType.ToString()] = serviceTypes.ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            if (vehicleTypeID != null)
            {
                PrepareVehicleData(claim, vehicleTypeID);
            }

            // Special case - fill rv types
            if (ViewData[StaticData.RVType.ToString()] == null)
            {
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

            return PartialView("_Claims_Vehicle_Service",claimModel);

        }


        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveDiagnosticCodes(int claimID, string selectedCodes, string codeType, int? primaryCode = 0)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var currentUser = LoggedInUserName;
            var facade = new ClaimsFacade();
            facade.SaveDiagnosticCodes(claimID, selectedCodes, codeType, primaryCode, currentUser);
            return Json(result);
        }

        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveClaimComments(int claimID, string commentText)
        {
            var claimsFacade = new ClaimsFacade();

            CommentFacade facade = new CommentFacade();
            var currentUser = LoggedInUserName;
            if (!string.IsNullOrEmpty(commentText))
            {
                facade.Save(CommentTypeNames.CLAIM, EntityNames.CLAIM, claimID, commentText, currentUser);                
            }
            return PartialView("_PreviousComments", claimsFacade.GetServiceDetails(claimID));
        }


        [NoCache]
        public ActionResult GetDiagnosticCodes(int claimID, int vehicleTypeID, string codeType)
        {
            var serviceRepository = new ClaimsRepository();
            var claimsFacade = new ClaimsFacade();

            ViewData[StaticData.CodeTypes.ToString()] = serviceRepository.GetCodeTypes().ToSelectListItem(x => x.Key, y => y.Value);
            
            
            if (string.IsNullOrEmpty(codeType))
            {
                codeType = "Ford Claim";
            }

            var model = claimsFacade.GetDiagnosticCodes(claimID, vehicleTypeID, codeType);
            var primaryCodes = (from n in model
                                where n.IsPrimary == true
                                select n).ToList<DiagnosticCodes_Result>();
            ViewData[StaticData.PrimaryCodes.ToString()] = primaryCodes.ToSelectListItem(x => x.CodeName, y => y.CodeName, true);
            ViewData["EnableCodeTypes"] = true;//codeType.Equals("Ford Standard");
            ViewData["ClaimID"] = claimID;
            ViewData["VehicleTypeID"] = vehicleTypeID;

            return PartialView("_DiagnosticCodes", model);
        }

        public ActionResult _GetDiagnosticCodes(int claimID, int vehicleTypeID, string codeType)
        {
            var claimsFacade = new ClaimsFacade();
            var model = claimsFacade.GetDiagnosticCodes(claimID, vehicleTypeID, codeType);
            return PartialView("_DiagnosticCodeCheckboxes", model);
        }

        [HttpPost]
        public ActionResult _GetSelectedDiagnosticCodesForClaim(int claimID)
        {
            var claimsFacade = new ClaimsFacade();
            var model = claimsFacade.GetDiagnosticCodes(claimID);
            return PartialView("_ClaimDiagnosticCodes", model ?? new List<BLL.Model.ServiceDiagnosticCodeModel>());
        }
    }


}
