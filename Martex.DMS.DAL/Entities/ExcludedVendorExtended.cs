using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.DAL.Entities
{
    /// <summary>
    /// 
    /// </summary>
    public class ExcludedVendorExtended
    {
        public int MemberShipID { get; set; }
        public int Height { get; set; }
        public List<ExcludedVendorItem> ExcludedList
        {
            get
            {
                if (this.MemberShipID > 0)
                {
                    var membeFacade = new MemberManagementRepository();
                    return membeFacade.GetExcludedVendorForMembership(this.MemberShipID);
                }
               return null;
            }
        }
    }

    /// <summary>
    /// 
    /// </summary>
    public class ExcludedVendorItem
    {
        public int ID { get; set; }
        public int VendorID { get; set; }
        public int MembershipID { get; set; }
        public string VendorNumber { get; set; }
        public string VendorName { get; set; }
    }

}
