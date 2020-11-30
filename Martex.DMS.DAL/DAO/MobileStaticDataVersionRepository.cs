using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO
{

    /// <summary>
    /// To manage the static data for Mobile
    /// </summary>
    public class MobileStaticDataVersionRepository
    {

        /// <summary>
        /// Gets mobile APIs static data versions .
        /// </summary>
        /// <returns></returns>
        public List<MobileStaticDataVersion> Get()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.MobileStaticDataVersions.ToList();
            }
        }
    }
}

