using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public class MobileStaticDataVersionFacade
    {
        MobileStaticDataVersionRepository repo = new MobileStaticDataVersionRepository();

        /// <summary>
        /// Gets mobile APIs static data versions .
        /// </summary>
        /// <returns></returns>
        public List<MobileStaticDataVersion> Get()
        {
            return repo.Get();
        }
    }
}

