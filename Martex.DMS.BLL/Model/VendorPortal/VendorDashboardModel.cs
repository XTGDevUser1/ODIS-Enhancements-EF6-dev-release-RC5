using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model.VendorPortal
{
    public class VendorDashboardModel
    {
        public List<VendorServiceCallActivity> VendorServiceCallActivity { get; set; }
        public List<Vendor_Dashboard_Profile_completeness_Result> Profile { get; set; }
        public Vendor_Dashboard_ServiceRatings_Result ServiceRatings { get; set; }
        public Vendor VendorDetails { get; set; }
        public List<VendorServiceType> ServiceTypes { get; set; }
        public List<Message> MessageList { get; set; }
    }

    public class VendorServiceCallActivity
    {
        public string Months { get; set; }
        public int TotalCalls { get; set; }
        public int AcceptedCalls { get; set; }
    }

    public class VendorServiceType
    {
        public string CategoryName { get; set; }
        public double Percentage { get; set; } 
    }
}
