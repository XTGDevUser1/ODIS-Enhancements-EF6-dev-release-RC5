using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class DBAuditFacade
    {

        /// <summary>
        /// Gets the DB audit.
        /// </summary>
        /// <returns></returns>
        public List<DBAudit> GetDBAudit()
        {
            return ReferenceDataRepository.GetDBAudit();
        }
    }
}
