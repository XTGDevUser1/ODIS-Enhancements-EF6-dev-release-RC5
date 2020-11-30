using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ClosedLoopRepository
    {

        /// <summary>
        /// Gets the name of the closed loop status by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ClosedLoopStatu GetClosedLoopStatusByName(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ClosedLoopStatus.Where(n => n.Name.Equals(name)).FirstOrDefault();
            }
        }
    }
}
