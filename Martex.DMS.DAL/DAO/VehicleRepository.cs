using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL.Common;
using System.Data.Entity;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class VehicleRepository
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VehicleRepository));
        /// <summary>
        /// Gets the member vehicles.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="memberId">The member id.</param>
        /// <param name="membershipId">The membership id.</param>
        /// <returns></returns>
        public List<Vehicles_Result> GetMemberVehicles(int programId, int memberId, int membershipId)
        {
            List<Vehicles_Result> vehicleList = new List<Vehicles_Result>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                vehicleList = dbContext.GetVehiclesForMember(programId, memberId, membershipId).ToList<Vehicles_Result>();
            }
            return vehicleList;
        }

        /// <summary>
        /// Gets the vehicle type by programe.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public List<ProgramVehicleType> GetVehicleTypeByPrograme(int programId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramVehicleType(programId).ToList<ProgramVehicleType>();
            }
        }

        /// <summary>
        /// Gets the max allowed.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <returns></returns>
        public int? GetMaxAllowed(int programId, int vehicleTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var maxAllowed = dbContext.GetMaxAllowedVehicles(programId, vehicleTypeId).Single<int?>();
                return maxAllowed;
            }
        }
        /// <summary>
        /// Gets the vehicle.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Vehicle GetVehicle(int id)
        {
            Vehicle returnValue = new Vehicle();
            using (DMSEntities dbContext = new DMSEntities())
            {
                returnValue = dbContext.Vehicles.Include("VehicleType")
                    .Include(v => v.VehicleCategory)
                    .Where(v => v.ID == id).FirstOrDefault<Vehicle>();
            }
            return returnValue;
        }

        /// <summary>
        /// Determines whether [is hagerty program] [the specified program ID].
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns>
        ///   <c>true</c> if [is hagerty program] [the specified program ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsHagertyProgram(int programID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                var result = from f in entities.Programs
                             join c in entities.Clients
                             on f.ClientID equals c.ID
                             where f.ID == programID
                             where c.Name.Equals("Hagerty", StringComparison.OrdinalIgnoreCase)
                             select f;

                if (result != null && result.Count() > 0)
                {
                    return true;
                }

                return false;

            }
        }

        /// <summary>
        /// Adds the or update vehicle.
        /// </summary>
        /// <param name="vehicleFromCase">The vehicle from case.</param>
        /// <param name="caseId">The case id.</param>
        /// <param name="add">if set to <c>true</c> [add].</param>
        public void AddOrUpdateVehicle(Vehicle vehicleFromCase, int? caseId, bool add = false)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vehicle vehicle = null;
                if (add)
                {
                    vehicle = new Vehicle();
                    vehicle.CreateBy = vehicleFromCase.ModifyBy;
                    vehicle.CreateDate = vehicleFromCase.ModifyDate;
                    vehicle.IsActive = true;
                }
                else
                {
                    vehicle = dbContext.Vehicles.Where(x => x.ID == vehicleFromCase.ID).FirstOrDefault();
                }
                if (vehicle != null)
                {
                    vehicle.VIN = vehicleFromCase.VIN;
                    vehicle.Year = vehicleFromCase.Year;
                    vehicle.Make = vehicleFromCase.Make;
                    vehicle.MakeOther = vehicleFromCase.MakeOther;
                    vehicle.Model = vehicleFromCase.Model;
                    vehicle.ModelOther = vehicleFromCase.ModelOther;
                    vehicle.LicenseNumber = vehicleFromCase.LicenseNumber;
                    vehicle.LicenseState = vehicleFromCase.LicenseState;
                    vehicle.VehicleLicenseCountryID = vehicleFromCase.VehicleLicenseCountryID;
                    vehicle.Description = vehicleFromCase.Description;
                    vehicle.Color = vehicleFromCase.Color;
                    vehicle.Length = vehicleFromCase.Length;
                    vehicle.Height = vehicleFromCase.Height;
                    vehicle.VehicleCategoryID = vehicleFromCase.VehicleCategoryID;
                    vehicle.VehicleTypeID = vehicleFromCase.VehicleTypeID;
                    vehicle.RVTypeID = vehicleFromCase.RVTypeID;
                    vehicle.TireSize = vehicleFromCase.TireSize;
                    vehicle.TireBrand = vehicleFromCase.TireBrand;
                    vehicle.TireBrandOther = vehicleFromCase.TireBrandOther;
                    vehicle.Transmission = vehicleFromCase.Transmission;
                    vehicle.Engine = vehicleFromCase.Engine;
                    vehicle.GVWR = vehicleFromCase.GVWR;
                    vehicle.Chassis = vehicleFromCase.Chassis;
                    vehicle.PurchaseDate = vehicleFromCase.PurchaseDate;
                    vehicle.WarrantyStartDate = vehicleFromCase.WarrantyStartDate;
                    vehicle.StartMileage = vehicleFromCase.StartMileage;
                    vehicle.EndMileage = vehicleFromCase.EndMileage;
                    vehicle.CurrentMileage = vehicleFromCase.CurrentMileage;
                    vehicle.MileageUOM = vehicleFromCase.MileageUOM;
                    vehicle.IsFirstOwner = vehicleFromCase.IsFirstOwner;
                    vehicle.IsSportUtilityRV = vehicleFromCase.IsSportUtilityRV;
                    vehicle.Source = vehicleFromCase.Source;
                    vehicle.TrailerTypeID = vehicleFromCase.TrailerTypeID;
                    vehicle.SerialNumber = vehicleFromCase.SerialNumber;
                    vehicle.NumberofAxles = vehicleFromCase.NumberofAxles;
                    vehicle.HitchTypeID = vehicleFromCase.HitchTypeID;
                    vehicle.HitchTypeOther = vehicleFromCase.HitchTypeOther;
                    vehicle.TrailerBallSize = vehicleFromCase.TrailerBallSize;
                    vehicle.TrailerBallSizeOther = vehicleFromCase.TrailerBallSizeOther;
                    vehicle.ModifyDate = vehicleFromCase.ModifyDate;
                    vehicle.ModifyBy = vehicleFromCase.ModifyBy;
                    vehicle.MembershipID = vehicleFromCase.MembershipID;

                    //TFS * 365
                    vehicle.WarrantyPeriod = vehicleFromCase.WarrantyPeriod;
                    vehicle.WarrantyPeriodUOM = vehicleFromCase.WarrantyPeriodUOM;
                    vehicle.WarrantyMileage = vehicleFromCase.WarrantyMileage;
                    vehicle.WarrantyEndDate = vehicleFromCase.WarrantyEndDate;

                }
                if (add)
                {
                    dbContext.Vehicles.Add(vehicle);
                    if (caseId != null)
                    {
                        Case currentCase = dbContext.Cases.Where(c => c.ID == caseId.Value).FirstOrDefault<Case>();
                        currentCase.VehicleID = vehicle.ID;
                    }
                }

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the member number.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public int? GetMemberNumber(int membershipId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //KB: Changed after member number was dropped during the development of member management module.
                Membership member = dbContext.Memberships.Where(m => m.ID == membershipId).FirstOrDefault<Membership>();
                if (member != null)
                {
                    int memberNumber;
                    bool result = int.TryParse(member.MembershipNumber, out memberNumber);
                    if (result)
                    {
                        return memberNumber;
                    }
                }
            }
            return null;
        }

        /// <summary>
        /// Gets the vehicle type id.
        /// </summary>
        /// <param name="vehicleTypeName">Name of the vehicle type.</param>
        /// <returns></returns>
        public int? GetVehicleTypeId(string vehicleTypeName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VehicleType vt = dbContext.VehicleTypes.Where(v => v.Name == vehicleTypeName).FirstOrDefault<VehicleType>();

                if (vt != null)
                {
                    return vt.ID;
                }
            }
            return 1;
        }

        public void TryDelete(int vehicleID)
        {
            try
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var v = dbContext.Vehicles.Where(vh => vh.ID == vehicleID).FirstOrDefault();
                    if (v != null)
                    {
                        logger.InfoFormat("Attempting to delete Vehicle : {0}", v.ID);
                        dbContext.Entry(v).State = EntityState.Deleted;
                        dbContext.SaveChanges();
                    }
                }
            }
            catch (Exception ex)
            {
                logger.WarnFormat("Could not delete vehicle {0} due to error [ {1} ]", vehicleID, ex.ToString());
                // Mark the vehicle as deleted if the delete fails.
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var v = dbContext.Vehicles.Where(vh => vh.ID == vehicleID).FirstOrDefault();
                    if (v != null)
                    {
                        v.IsActive = false;
                        dbContext.SaveChanges();
                        logger.InfoFormat("Marked the vehicle {0} as inactive", vehicleID);
                    }
                }
            }
        }

        public List<VINSearch_Result> SearchByVIN(string searchText, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.SearchByVIN(searchText, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VINSearch_Result>();
            }
        }

        //Lakshmi - Hagerty Integration 
        /// <summary>
        /// Get list of Vehicle info by membership number.
        /// </summary>
        /// <param name="membershipNumber">The Membership Number</param>
        /// <returns></returns>
        public Vehicle[] GetVehiclesInfoByMemberShipNumber(string membershipNumber, int parentPgmID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vehicle[] vehicleInfo = (from v in dbContext.Vehicles
                                         join ms in dbContext.Memberships on v.MembershipID equals ms.ID
                                         join m in dbContext.Members on ms.ID equals m.MembershipID
                                         join p in dbContext.Programs on m.ProgramID equals p.ID
                                         where (ms.MembershipNumber == membershipNumber) & (p.ParentProgramID == parentPgmID) & (m.IsPrimary.Value == true)
                                         select v).ToArray();

                return vehicleInfo;

            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Add a Vehicle in Vehicle table.
        /// </summary>
        /// <param name="vehicleInfo">Vehicle Info</param>
        /// <returns></returns>
        public void AddVehicle(Vehicle vehicleInfo)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Vehicles.Add(vehicleInfo);
                dbContext.SaveChanges();
            }
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Get Vehicle Category by vehicle make.
        /// </summary>
        /// <param name="vehicleMake">vehicle make name</param>
        /// <returns></returns>
        public int? GetVehicleCategory(string vehicleMake)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VehicleMakeModel vMake = dbContext.VehicleMakeModels.Where(vm => vm.Make == vehicleMake).FirstOrDefault<VehicleMakeModel>();
                if (vMake != null)
                {
                    return vMake.VehicleCategoryID;
                }
            }
            return null;
        }

        //Lakshmi - Hagerty Integration
        public void SaveHagertyVehicle(Vehicle vehicleInfo)
        {
            Vehicle existingDetails = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                existingDetails = dbContext.Vehicles.Where(u => u.ID == vehicleInfo.ID).FirstOrDefault();
                if (existingDetails != null)
                {
                    existingDetails.Make = vehicleInfo.Make;
                    existingDetails.Model = vehicleInfo.Model;
                    existingDetails.Year = vehicleInfo.Year;
                    existingDetails.VehicleCategoryID = vehicleInfo.VehicleCategoryID;
                    existingDetails.VehicleTypeID = vehicleInfo.VehicleTypeID;
                    existingDetails.IsActive = vehicleInfo.IsActive;
                    existingDetails.ModifyBy = vehicleInfo.ModifyBy;
                    existingDetails.ModifyDate = vehicleInfo.ModifyDate;

                    dbContext.Entry(existingDetails).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        public void UpdateVehicleTypeDetails(Vehicle model, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vehicle existingDetails = dbContext.Vehicles.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingDetails != null)
                {
                    existingDetails.VehicleTypeID = model.VehicleTypeID;
                    existingDetails.ModifyBy = LoggedInUserName;
                    existingDetails.ModifyDate = DateTime.Now;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Saves the vehicle details.
        /// </summary>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="LoggedInUserName">Name of the logged in user.</param>
        /// <returns></returns>
        public Vehicle SaveVehicleDetails(Vehicle vehicle, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                vehicle.CreateBy = LoggedInUserName;
                vehicle.CreateDate = DateTime.Now;
                dbContext.Vehicles.Add(vehicle);
                dbContext.SaveChanges();
            }
            return vehicle;
        }

        public List<Vehicle> GetVehiclesByMakeModelAndYear(string make, string model, string year)
        {
            List<Vehicle> vehicleList = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                vehicleList = dbContext.Vehicles.Where(a =>
                    (a.Make == make || (a.Make == "Other" && a.MakeOther == make))
                    && (a.Model == model || ("Other".Equals(a.Model) && a.Model == model))
                    && a.Year == year
                    ).ToList();
            }
            return vehicleList;
        }

        public MemberApiModel SaveOrUpdateVehicleTypeDetailsForWebService(MemberApiModel model, bool allowVehicleInsert = true, bool allowVehicleUpdate = true)
        {
            #region Check if existing vehicle record exists before creating new.

            Vehicle existingVehicle = null;
            if (model.VehicleID != null)
            {
                existingVehicle = GetVehicle(model.VehicleID.GetValueOrDefault());
            }
            else
            {
                List<Vehicle> vehiclesList = GetVehiclesForMemberOrMembership(model.InternalCustomerID, model.InternalCustomerGroupID);
                if (vehiclesList != null && vehiclesList.Count > 0)
                {
                    foreach (var vehicle in vehiclesList)
                    {
                        if (!string.IsNullOrEmpty(model.VehicleVIN) && model.VehicleVIN.Equals(vehicle.VIN, StringComparison.InvariantCultureIgnoreCase))
                        {
                            /*  If VIN is passed, query by VIN, MembershipNumber and update vehicle information if a match is found. */
                            existingVehicle = vehicle;
                        }
                        else if (string.IsNullOrEmpty(model.VehicleVIN) && !string.IsNullOrEmpty(model.VehicleMake) && !string.IsNullOrEmpty(model.VehicleModel) && model.VehicleYear != null)
                        {
                            /*  If Year, Make, Model is provided, find a matching vehicle for that membership.  If a match is found, then update it. */
                            if (
                                model.VehicleYear.GetValueOrDefault().ToString().Equals(vehicle.Year) &&
                                model.VehicleMake.Equals((!string.IsNullOrEmpty(vehicle.Make) && vehicle.Make == "Other" ? vehicle.MakeOther : vehicle.Make), StringComparison.InvariantCultureIgnoreCase) &&
                                model.VehicleModel.Equals((!string.IsNullOrEmpty(vehicle.Model) && vehicle.Model == "Other" ? vehicle.ModelOther : vehicle.Model), StringComparison.InvariantCultureIgnoreCase)
                                )
                            {
                                existingVehicle = vehicle;
                            }
                        }
                    }
                }
            }

            #endregion

            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
            int? vehicleCategoryID = model.VehicleCategoryID,
                   rvTypeID = model.RVTypeID,
                   vehicleTypeID = model.VehicleTypeID,
                   vehicleYear = model.VehicleYear;

            VehicleType vehicleType = lookUpRepo.GetVehicleTypeByName(model.VehicleType);
            if (vehicleType == null)
            {
                vehicleType = lookUpRepo.GetVehicleTypeByName(VehicleTypeNames.AUTO);
            }
            vehicleTypeID = vehicleType.ID;

            if (vehicleCategoryID == null)
            {
                int? defaultValue = null;
                if (!string.IsNullOrEmpty(model.VehicleMake) && !string.IsNullOrEmpty(model.VehicleModel) && vehicleYear != null)
                {
                    defaultValue = ReferenceDataRepository.GetVehicleTypeDefaultWeight(vehicleTypeID.Value, model.VehicleMake, model.VehicleModel);
                }                
                vehicleCategoryID = defaultValue;
            }

            string vehicleMake = null,
               vehicleMakeOther = null,
               vehicleModel = null,
               vehicleModelOther = null;
            var makeModel = ReferenceDataRepository.GetMakeModel(vehicleTypeID.Value, model.VehicleMake, model.VehicleModel).FirstOrDefault();
            if (vehicleType.Name == VehicleTypeNames.RV)
            {
                
                if (makeModel != null)
                {
                    vehicleMake = model.VehicleMake;
                    vehicleModel = model.VehicleModel;
                    if (rvTypeID == null)
                    {
                        rvTypeID = makeModel.RVTypeID;
                    }
                }
                else
                {
                    vehicleMake = "Other";
                    vehicleMakeOther = model.VehicleMake;
                    vehicleModel = "Other";
                    vehicleModelOther = model.VehicleModel;
                }
            }
            else
            {   
                if (makeModel != null)
                {
                    vehicleMake = model.VehicleMake;
                    vehicleModel = model.VehicleModel;
                }
                else
                {
                    vehicleMake = "Other";
                    vehicleMakeOther = model.VehicleMake;
                    vehicleModel = "Other";
                    vehicleModelOther = model.VehicleModel;
                }
            }

            // Set the IDs back on model.
            model.VehicleMake = vehicleMake;
            model.VehicleMakeOther = vehicleMakeOther;
            model.VehicleModel = vehicleModel;
            model.VehicleModelOther = vehicleModelOther;
            model.VehicleTypeID = vehicleTypeID;
            model.VehicleCategoryID = vehicleCategoryID;
            model.RVTypeID = rvTypeID;

            if (existingVehicle != null && allowVehicleUpdate)
            {

                existingVehicle.VehicleCategoryID = vehicleCategoryID;
                existingVehicle.RVTypeID = rvTypeID;
                existingVehicle.VehicleTypeID = vehicleTypeID;
                existingVehicle.Make = vehicleMake;
                existingVehicle.MakeOther = vehicleMakeOther;
                existingVehicle.Model = vehicleModel;
                existingVehicle.ModelOther = vehicleModelOther;
                //TFS : 1413
                if (ReferenceDataRepository.CheckIsVINValid(model.VehicleVIN))
                {
                    existingVehicle.VIN = model.VehicleVIN;
                }
                existingVehicle.Year = model.VehicleYear.GetValueOrDefault().ToString();
                if (!string.IsNullOrEmpty(model.VehicleColor))
                {
                    existingVehicle.Color = model.VehicleColor;
                }
                existingVehicle.ModifyDate = DateTime.Now;
                existingVehicle.ModifyBy = model.CurrentUser;
                existingVehicle.IsActive = true;
                if (model.VehicleWarrantyPeriod != null)
                {
                    existingVehicle.WarrantyPeriod = model.VehicleWarrantyPeriod;
                }
                if (!string.IsNullOrEmpty(model.VehicleWarrantyPeriodUOM))
                {
                    existingVehicle.WarrantyPeriodUOM = model.VehicleWarrantyPeriodUOM;
                }
                if (model.VehicleWarrantyMiles != null)
                {
                    existingVehicle.WarrantyMileage = model.VehicleWarrantyMiles;
                }
                if (!string.IsNullOrEmpty(model.VehicleWarrantyMilesUOM))
                {
                    existingVehicle.MileageUOM = model.VehicleWarrantyMilesUOM;
                }
                if (model.VehicleCurrentMileage != null)
                {
                    existingVehicle.CurrentMileage = model.VehicleCurrentMileage;
                }
                AddOrUpdateVehicle(existingVehicle, null);
                model.VehicleID = existingVehicle.ID;
            }
            else if (allowVehicleInsert)
            {
                Vehicle vehicle = new Vehicle()
                {
                    VehicleCategoryID = vehicleCategoryID,
                    RVTypeID = rvTypeID,
                    VehicleTypeID = vehicleTypeID,
                    Make = vehicleMake,
                    MakeOther = vehicleMakeOther,
                    Model = vehicleModel,
                    ModelOther = vehicleModelOther,
                    MembershipID = model.InternalCustomerGroupID,
                    MemberID = model.InternalCustomerID,
                    VIN = ReferenceDataRepository.CheckIsVINValid(model.VehicleVIN) ? model.VehicleVIN : null,
                    Year = model.VehicleYear.GetValueOrDefault().ToString(),
                    Color = model.VehicleColor.NullIfBlank(),
                    CreateDate = DateTime.Now,
                    CreateBy = model.CurrentUser,
                    Source = "Web Service",
                    IsActive = true,
                    WarrantyPeriod = model.VehicleWarrantyPeriod,
                    WarrantyPeriodUOM = model.VehicleWarrantyPeriodUOM,
                    WarrantyMileage = model.VehicleWarrantyMiles,
                    MileageUOM = model.VehicleWarrantyMilesUOM,
                    CurrentMileage = model.VehicleCurrentMileage,
                    Chassis = model.VehicleChassis.NullIfBlank(),
                    Engine = model.VehicleEngine.NullIfBlank(),
                    LicenseState = model.LicenseState.NullIfBlank(),
                    LicenseNumber = model.LicenseNumber.NullIfBlank()
                };

                if (!string.IsNullOrWhiteSpace(model.LicenseCountry))
                {
                    var countryByCode = lookUpRepo.GetCountryByCode(model.LicenseCountry);
                    if (countryByCode != null)
                    {
                        vehicle.VehicleLicenseCountryID = countryByCode.ID;
                    }
                }

                VehicleRepository vehicleRepository = new VehicleRepository();
                vehicle = vehicleRepository.SaveVehicleDetails(vehicle, model.CurrentUser);
                model.VehicleID = vehicle.ID;
            }
            return model;
        }


        /// <summary>
        /// Gets the vehicles for member or membership.
        /// </summary>
        /// <param name="memberID">The member identifier.</param>
        /// <param name="membershipID">The membership identifier.</param>
        /// <returns></returns>
        public List<Vehicle> GetVehiclesForMemberOrMembership(int? memberID, int? membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Vehicles.Where(v => (memberID != null && v.MemberID == memberID) ||
                                                (membershipID != null && v.MembershipID == membershipID && v.MemberID == null)

                                               &&
                                               v.IsActive == true).ToList();
            }
        }
    }
}
