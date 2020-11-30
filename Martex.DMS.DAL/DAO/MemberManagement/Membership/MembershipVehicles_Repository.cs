using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    public partial class MemberManagementRepository
    {

        /// <summary>
        /// Gets the vehicles by membership.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<Vehicles_Result> GetVehiclesByMembership(int membershipID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVehiclesForMembership(membershipID).ToList<Vehicles_Result>();
            }
        }
    }
}
