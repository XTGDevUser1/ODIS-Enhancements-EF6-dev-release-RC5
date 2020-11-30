using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class DashBoardFacade
    {
        #region Private Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ActivityFacade));

        /// <summary>
        /// The repository
        /// </summary>
        DashBoardRepository rep = new DashBoardRepository();

        #endregion

        #region Public Methods

        /// <summary>
        /// Gets the dispatch dash board model.
        /// </summary>
        /// <returns></returns>
        public DispatchDashBoardModel GetDispatchDashBoardModel()
        {

            MessageFacade messagefacade = new MessageFacade();
            ServiceFacade serviceFacade = new ServiceFacade();
            DispatchDashBoardModel model = new DispatchDashBoardModel();
            model.DashboardDispatchChart = rep.GetDashBoardList();
            model.DashboardDispatchChartLabels = rep.GetDashBoardLabelsList();
            model.DashboardMessages = messagefacade.GetMessages(MessageScopeNames.DISPATCH);
            model.DashboardSRCount = serviceFacade.GetDashboradServiceRequestCount();
            return model;
        }

        #endregion
    }
}
