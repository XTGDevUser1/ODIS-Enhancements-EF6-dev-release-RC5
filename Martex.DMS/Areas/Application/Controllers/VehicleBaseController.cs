using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class VehicleBaseController : BaseController
    {
        #region Protected Methods
        /// <summary>
        /// Gets the RV years.
        /// </summary>
        /// <param name="isSelectRequired">if set to <c>true</c> [is select required].</param>
        /// <returns></returns>
        protected List<SelectListItem> GetYears(bool isSelectRequired = true)
        {
            List<SelectListItem> years = new List<SelectListItem>();
            if (isSelectRequired)
            {
                years.Insert(0, new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            }
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
        /// Gets the RV type values.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        protected IEnumerable<SelectListItem> GetRVTypeValues(string make, string model)
        {
            var list = ReferenceDataRepository.GetRVType(make, model).ToSelectListItem(x => x.ID.ToString(), y => y.Name);
            return list;
        }
        /// <summary>
        /// Gets the trailer years.
        /// </summary>
        /// <param name="isSelectRequired">if set to <c>true</c> [is select required].</param>
        /// <returns></returns>
        //protected List<SelectListItem> GetTrailerYears(bool isSelectRequired = true)
        //{
        //    List<SelectListItem> years = new List<SelectListItem>();
        //    if (isSelectRequired)
        //    {
        //        years.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
        //    }
        //    int currentYear = DateTime.Now.Year + 1;
        //    string sYear = string.Empty;
        //    for (int i = 1; i <= 20; i++)
        //    {
        //        sYear = currentYear.ToString();
        //        years.Add(new SelectListItem() { Text = sYear, Value = sYear });
        //        currentYear -= 1;
        //    }
        //    return years;
        //}

        /// <summary>
        /// Gets the vehicle years.
        /// </summary>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <returns></returns>
        //protected List<SelectListItem> GetVehicleYears(int vehicleTypeID)
        //{
        //    List<SelectListItem> list;
        //    switch (vehicleTypeID)
        //    {
        //        case 1: // Auto
        //            list = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), false).ToList();
        //            break;
        //        case 2: // RV
        //            list = GetRVYears();
        //            break;
        //        case 3: //Motorcycle
        //            list = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), false).ToList();
        //            break;
        //        case 4: // Trailer
        //            list = GetTrailerYears();
        //            break;
        //        default:
        //            list = new List<SelectListItem>();
        //            //list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
        //            break;
        //    }
        //    return list;
        //}

        /// <summary>
        /// Gets the vehicle make.
        /// </summary>
        /// <param name="Year">The year.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <returns></returns>
        protected List<SelectListItem> GetVehicleMake(int vehicleTypeID)
        {   
            List<SelectListItem> list = null;
            logger.InfoFormat("Retrieving Combo Vehicle Make for given Vehicle Type {0}", vehicleTypeID);
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

            list = ReferenceDataRepository.GetVehicleMake(vehicleTypeID).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), false).ToList();
            logger.Info("Retrieving Finished for Combo Vehicle Make");
            //switch (vehicleTypeID)
            //{
            //    case 1: // Auto
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

            //        list = ReferenceDataRepository.GetVehicleMake(year).Distinct(makeDistinct).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), false).ToList();
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

            //        list = ReferenceDataRepository.GetRVMake().Distinct(makeDistinctForRv).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), false).ToList();
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

            //        list = ReferenceDataRepository.GetMotorcycleMake().Distinct(mcMakeDistinct).OrderBy(a => a.Make).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), false).ToList();
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

            //        list = ReferenceDataRepository.GetTrailerMake().Distinct(makeDistinctForTrailer).ToSelectListItem(x => x.Make.ToString(), y => y.Make.ToString(), false).ToList();
            //        break;
            //    default:
            //        list = new List<SelectListItem>();
            //        //list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            //        break;
            //}

            return list;
        }

        /// <summary>
        /// Gets the I equality comparer for vehicle model.
        /// </summary>
        /// <returns></returns>
        protected static GenericIEqualityComparer<MakeModel> GetIEqualityComparerForVehicleModel()
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
            return modelDistinct;
        }

        #endregion

        #region Public Methods
        /// <summary>
        /// Gets the vehicle model.
        /// </summary>
        /// <param name="make">The make.</param>
        /// <param name="year">The year.</param>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <returns></returns>
        public List<SelectListItem> GetVehicleModel(string make, int vehicleType)
        {
            List<SelectListItem> list = null;
            logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);
            GenericIEqualityComparer<MakeModel> modelDistinct = GetIEqualityComparerForVehicleModel();
            list = ReferenceDataRepository.GetVehicleModel(vehicleType,make,true).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Model.ToString(), false).ToList();
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            //switch (vehicleType)
            //{
            //    case 1: // Auto
            //        logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);
            //        GenericIEqualityComparer<VehicleMakeModel> modelDistinct = GetIEqualityComparerForVehicleModel();
            //        list = ReferenceDataRepository.GetVehicleModel(make, year.GetValueOrDefault(), true).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Model.ToString(), false).ToList();
            //        logger.Info("Retrieving Finished for Combo Vehicle Model");
            //        break;
            //    case 2: // RV
            //        logger.InfoFormat("Retrieving RV models for Make {0} ", make);
            //        GenericIEqualityComparer<RVMakeModel> modelDistinctRV = new GenericIEqualityComparer<RVMakeModel>(
            //           (x, y) =>
            //           {
            //               return x.Model.Trim() == y.Model.Trim();
            //           },
            //           (a) =>
            //           {
            //               return a.Model.Trim().GetHashCode();
            //           }
            //           );

            //        list = ReferenceDataRepository.GetRVModel(make, true).Distinct(modelDistinctRV).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), false).ToList();
            //        logger.Info("Retrieving Finished for Combo Vehicle Model");
            //        break;
            //    case 3: //Motorcycle
            //        list = ReferenceDataRepository.GetMotorcycleModel(make).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), false).ToList();
            //        logger.Info("Retrieving Finished for Combo Vehicle Model");
            //        break;
            //    case 4: //Trailer
            //        logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);
            //        GenericIEqualityComparer<TrailerMakeModel> modelDistinctTrailer = new GenericIEqualityComparer<TrailerMakeModel>(
            //                  (x, y) =>
            //                  {
            //                      return x.Model.Trim() == y.Model.Trim();
            //                  },
            //                  (a) =>
            //                  {
            //                      return a.Model.Trim().GetHashCode();
            //                  }
            //                  );

            //        list = ReferenceDataRepository.GetVehicleModelForTrailer(make, year.GetValueOrDefault()).Distinct(modelDistinctTrailer).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), false).ToList();
            //        logger.Info("Retrieving Finished for Combo Vehicle Model");
            //        break;
            //    default:
            //        list = new List<SelectListItem>();
            //        list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            //        break;
            //}
            return list;
        }


        public WarrantyInformation GetWarrantyInformation(int vehicleTypeID, int? year, string make, string model, string memberHomeAddressCountryCode)
        {
            VehicleTypes vehicleType = VehicleTypes.Auto;
            Enum.TryParse(vehicleTypeID.ToString(), out vehicleType);
            WarrantyInformation wi = new WarrantyInformation();

            logger.InfoFormat("Trying to Collect Warranty Information. Checking DefaultWarrantyTermsFromVehicle is configured or not for Program ID {0}", DMSCallContext.ProgramID);
            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var result = programMaintenanceRepository.GetProgramInfo(DMSCallContext.ProgramID, "Vehicle", "Validation");
            var isDefaultWarrantyTermsFromVehicleConfigured = result.Where(x => (x.Name.Equals("DefaultWarrantyTermsFromVehicle", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault() != null;
            if (isDefaultWarrantyTermsFromVehicleConfigured)
            {
                logger.InfoFormat("DefaultWarrantyTermsFromVehicle is configured for Program ID {0} So collecting WarrantyInformation", DMSCallContext.ProgramID);
                var vehicleMakeModel = ReferenceDataRepository.GetMakeModel((int)vehicleType, make, model).FirstOrDefault();
                if (vehicleMakeModel != null)
                {

                    if ("CA".Equals(memberHomeAddressCountryCode, StringComparison.InvariantCultureIgnoreCase))
                    {
                        wi.WarrantyMileage = vehicleMakeModel.WarrantyMileageKilometers;
                        wi.WarrantyMileageUOM = "Kilometers";
                    }
                    else
                    {
                        wi.WarrantyMileage = vehicleMakeModel.WarrantyMileageMiles;
                        wi.WarrantyMileageUOM = "Miles";
                    }
                    wi.WarrantyPeriod = vehicleMakeModel.WarrantyPeriod;
                    wi.WarrantyPeriodUOM = vehicleMakeModel.WarrantyPeriodUOM;
                }

                //switch (vehicleType)
                //{
                //    case VehicleTypes.Auto:
                        
                //        if (vehicleMakeModel != null)
                //        {

                //            if ("CA".Equals(memberHomeAddressCountryCode, StringComparison.InvariantCultureIgnoreCase))
                //            {
                //                wi.WarrantyMileage = vehicleMakeModel.WarrantyMileageKilometers;
                //                wi.WarrantyMileageUOM = "Kilometers";
                //            }
                //            else
                //            {
                //                wi.WarrantyMileage = vehicleMakeModel.WarrantyMileageMiles;
                //                wi.WarrantyMileageUOM = "Miles";
                //            }
                //            wi.WarrantyPeriod = vehicleMakeModel.WarrantyPeriod;
                //            wi.WarrantyPeriodUOM = vehicleMakeModel.WarrantyPeriodUOM;
                //        }
                //        break;
                //    case VehicleTypes.RV:
                //        var rvMakeModel = ReferenceDataRepository.GetRVMakeModel(make, model).FirstOrDefault();
                //        if (rvMakeModel != null)
                //        {

                //            if ("CA".Equals(memberHomeAddressCountryCode, StringComparison.InvariantCultureIgnoreCase))
                //            {
                //                wi.WarrantyMileage = rvMakeModel.WarrantyMileageKilometers;
                //                wi.WarrantyMileageUOM = "Kilometers";
                //            }
                //            else
                //            {
                //                wi.WarrantyMileage = rvMakeModel.WarrantyMileageMiles;
                //                wi.WarrantyMileageUOM = "Miles";
                //            }

                //            wi.WarrantyPeriod = rvMakeModel.WarrantyPeriod;
                //            wi.WarrantyPeriodUOM = rvMakeModel.WarrantyPeriodUOM;
                //        }
                //        break;
                //    default:
                //        break;
                //}
            }
            else
            {
                logger.InfoFormat("DefaultWarrantyTermsFromVehicle is not configured for Program ID {0}", DMSCallContext.ProgramID);
            }

            return wi;
        }
        #endregion

    }
}
