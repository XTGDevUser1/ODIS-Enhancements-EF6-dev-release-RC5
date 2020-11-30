using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.DAO;
using ClientPortal.Common;
using Martex.DMS.DAL;
using ClientPortal.Models;


namespace ClientPortal.Areas.Application.Controllers
{
    public class VehicleBaseController : BaseController
    {
        protected List<SelectListItem> GetRVYears(bool isSelectRequired = true)
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

        protected List<SelectListItem> GetTrailerYears(bool isSelectRequired = true)
        {
            List<SelectListItem> years = new List<SelectListItem>();
            if (isSelectRequired)
            {
                years.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            }
            int currentYear = DateTime.Now.Year + 1;
            string sYear = string.Empty;
            for (int i = 1; i <= 20; i++)
            {
                sYear = currentYear.ToString();
                years.Add(new SelectListItem() { Text = sYear, Value = sYear });
                currentYear -= 1;
            }

            return years;
        }

        protected List<SelectListItem> GetVehicleYears(int vehicleTypeID)
        {
            List<SelectListItem> list;
            switch (vehicleTypeID)
            {
                case 1: // Auto
                    list = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), true).ToList();
                    break;
                case 2: // RV
                    list = GetRVYears();
                    break;
                case 3: //Motorcycle
                    list = ReferenceDataRepository.GetVehicleYears().ToSelectListItem<VehicleYears_Result>(x => x.Year.Value.ToString(), y => y.Year.Value.ToString(), true).ToList();
                    break;
                case 4: // Trailer
                    list = GetTrailerYears();
                    break;
                default:
                    list = new List<SelectListItem>();
                    list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
                    break;


            }
            return list;
        }

        protected List<SelectListItem> GetVehicleMake(string Year, int vehicleTypeID)
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

        protected static GenericIEqualityComparer<VehicleMakeModel> GetIEqualityComparerForVehicleModel()
        {
            GenericIEqualityComparer<VehicleMakeModel> modelDistinct = new GenericIEqualityComparer<VehicleMakeModel>(
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

        public List<SelectListItem> GetVehicleModel(string make, double? year, int vehicleType)
        {
            List<SelectListItem> list = null;
            switch (vehicleType)
            {
                case 1: // Auto
                    logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);
                    GenericIEqualityComparer<VehicleMakeModel> modelDistinct = GetIEqualityComparerForVehicleModel();
                    list = ReferenceDataRepository.GetVehicleModel(make, year.GetValueOrDefault(), true).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.ID.ToString(), y => y.Model.ToString(), true).ToList();
                    logger.Info("Retrieving Finished for Combo Vehicle Model");
                    break;
                case 2: // RV
                    logger.InfoFormat("Retrieving RV models for Make {0} ", make);
                    GenericIEqualityComparer<RVMakeModel> modelDistinctRV = new GenericIEqualityComparer<RVMakeModel>(
                       (x, y) =>
                       {
                           return x.Model.Trim() == y.Model.Trim();
                       },
                       (a) =>
                       {
                           return a.Model.Trim().GetHashCode();
                       }
                       );

                    list = ReferenceDataRepository.GetRVModel(make, true).Distinct(modelDistinctRV).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), true).ToList();
                    logger.Info("Retrieving Finished for Combo Vehicle Model");
                    break;
                case 3: //Motorcycle
                    list = ReferenceDataRepository.GetMotorcycleModel(make).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), true).ToList();
                    logger.Info("Retrieving Finished for Combo Vehicle Model");
                    break;
                case 4: //Trailer
                    logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);
                    GenericIEqualityComparer<TrailerMakeModel> modelDistinctTrailer = new GenericIEqualityComparer<TrailerMakeModel>(
                              (x, y) =>
                              {
                                  return x.Model.Trim() == y.Model.Trim();
                              },
                              (a) =>
                              {
                                  return a.Model.Trim().GetHashCode();
                              }
                              );

                    list = ReferenceDataRepository.GetVehicleModelForTrailer(make, year.GetValueOrDefault()).Distinct(modelDistinctTrailer).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString(), true).ToList();
                    logger.Info("Retrieving Finished for Combo Vehicle Model");
                    break;
                default:
                    list = new List<SelectListItem>();
                    list.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
                    break;
            }
            return list;
        }

    }
}
