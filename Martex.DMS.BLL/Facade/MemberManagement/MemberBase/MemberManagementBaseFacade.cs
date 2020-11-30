using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL.DAO;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade.MemberManagement.MemberBase
{
    /// <summary>
    /// MemberManagementBaseFacade
    /// </summary>
    public class MemberManagementBaseFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MemberManagementBaseFacade));
        #endregion

        #region Private Members
        /// <summary>
        /// The Member Management Repository
        /// </summary>
        public MemberManagementRepository repository = new MemberManagementRepository();
        #endregion
    }
}
