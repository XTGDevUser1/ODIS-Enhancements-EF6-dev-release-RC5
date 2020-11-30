using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class VendorPortalDashboardFacade
    {
        VendorPortalDashboardRepository repository = new VendorPortalDashboardRepository();

        /// <summary>
        /// Gets the vendor dashboard service call activity.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorServiceCallActivity> GetVendorDasboardServiceCallActivity(int vendorID)
        {
            List<VendorServiceCallActivity> model = new List<VendorServiceCallActivity>();
            List<Vendor_Dashboard_ServiceCallActivity_Result> result = repository.GetVendorDashboardServiceCallActivity(vendorID);
            foreach (Vendor_Dashboard_ServiceCallActivity_Result temp in result)
            {
                model.Add(new VendorServiceCallActivity()
                {
                    AcceptedCalls = temp.AcceptedCalls,
                    TotalCalls = temp.TotalCalls,
                    Months = GetMonth(temp.MonthNumber.GetValueOrDefault())
                });
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor dashboard service types.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorServiceType> GetVendorDashboardServiceTypes(int vendorID)
        {
            List<VendorDashboardServiceTypes_Result> list = repository.GetVendorDashboardServiceTypes(vendorID);
            List<VendorServiceType> serviceTypes = new List<VendorServiceType>();
            foreach (VendorDashboardServiceTypes_Result temp in list)
            {
                serviceTypes.Add(new VendorServiceType()
                {
                    CategoryName = temp.ProductCategoryName,
                    Percentage = temp.ServicePercentage.GetValueOrDefault()
                });
            }
            return serviceTypes;
        }

        /// <summary>
        /// Gets the month.
        /// </summary>
        /// <param name="monthNumber">The month number.</param>
        /// <returns></returns>
        private string GetMonth(int monthNumber)
        {
            int year = DateTime.Now.Year;
            int lastYear = year - 1;
            string returnYear = year.ToString().Substring(2, 2);
            string returnLastYear = lastYear.ToString().Substring(2, 2);
            int month = DateTime.Now.Month;
            string yearToAppend = "";
            string returnMonth = "";
            switch (monthNumber)
            {
                case 1:
                    returnMonth = "Jan";
                    break;
                case 2:
                    returnMonth = "Feb";
                    break;
                case 3:
                    returnMonth = "Mar";
                    break;
                case 4:
                    returnMonth = "Apr";
                    break;
                case 5:
                    returnMonth = "May";
                    break;
                case 6:
                    returnMonth = "Jun";
                    break;
                case 7:
                    returnMonth = "Jul";
                    break;
                case 8:
                    returnMonth = "Aug";
                    break;
                case 9:
                    returnMonth = "Sep";
                    break;
                case 10:
                    returnMonth = "Oct";
                    break;
                case 11:
                    returnMonth = "Nov";
                    break;
                case 12:
                    returnMonth = "Dec";
                    break;
                default:
                    returnMonth = "NA";
                    break;

            }
            if (monthNumber <= month)
            {
                yearToAppend = returnYear;
            }

            else if (monthNumber > month && monthNumber <= 12)
            {
                yearToAppend = returnLastYear;
            }
            returnMonth += "-" + yearToAppend;
            return returnMonth;
        }

        /// <summary>
        /// Gets the vendor dashboard.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorDashboardModel GetVendorDashboard(int vendorID)
        {
            VendorDashboardModel model = new VendorDashboardModel();
            model.VendorServiceCallActivity = GetVendorDasboardServiceCallActivity(vendorID);
            model.Profile = repository.GetVendorDashboardProfileCompleteness(vendorID);
            model.ServiceRatings = repository.GetVendorDashboardServiceRatings(vendorID).FirstOrDefault();
            model.VendorDetails = new VendorManagementRepository().Get(vendorID);
            model.ServiceTypes = GetVendorDashboardServiceTypes(vendorID);

            if (model.ServiceRatings == null)
            {
                model.ServiceRatings = new Vendor_Dashboard_ServiceRatings_Result();
            }

            return model;
        }
    }
}
