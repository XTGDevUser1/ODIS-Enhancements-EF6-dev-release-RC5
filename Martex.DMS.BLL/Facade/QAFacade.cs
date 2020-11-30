using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// QAFacade
    /// </summary>
    public class QAFacade
    {
        /// <summary>
        /// Gets the qa concern type list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<QAConcernTypeList_Result> GetQAConcernTypeList(PageCriteria pc)
        {
            var qARepository = new QARepository();
            return qARepository.GetQAConcernTypeList(pc);
        }

        /// <summary>
        /// Deletes the type of the concern.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        public void DeleteConcernType(int? concernTypeId)
        {
            var qARepository = new QARepository();
            qARepository.DeleteConcernType(concernTypeId.GetValueOrDefault());
        }

        /// <summary>
        /// Gets the type of the concern.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        /// <returns></returns>
        public ConcernType GetConcernType(int? concernTypeId)
        {
            var qARepository = new QARepository();
            return qARepository.GetConcernType(concernTypeId.GetValueOrDefault());
        }

        /// <summary>
        /// Saves the type of the concern.
        /// </summary>
        /// <param name="concernType">Type of the concern.</param>
        public void SaveConcernType(ConcernType concernType)
        {
            var qARepository = new QARepository();
            qARepository.SaveConcernType(concernType);
        }

        /// <summary>
        /// Gets the qa concern list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="concernTypeID">The concern type identifier.</param>
        /// <returns></returns>
        public List<QAConcernList_Result> GetQAConcernList(PageCriteria pc, int? concernTypeID)
        {
            var qARepository = new QARepository();
            return qARepository.GetQAConcernList(pc, concernTypeID);
        }
        /// <summary>
        /// Deletes the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        public void DeleteConcern(int? concernId)
        {
            var qARepository = new QARepository();
            qARepository.DeleteConcern(concernId.GetValueOrDefault());
        }
        /// <summary>
        /// Saves the concern.
        /// </summary>
        /// <param name="concern">The concern.</param>
        public void SaveConcern(Concern concern)
        {
            var qARepository = new QARepository();
            qARepository.SaveConcern(concern);
        }
        /// <summary>
        /// Gets the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        /// <returns></returns>
        public Concern GetConcern(int? concernId)
        {
            var qARepository = new QARepository();
            return qARepository.GetConcern(concernId.GetValueOrDefault());
        }
    }
}
