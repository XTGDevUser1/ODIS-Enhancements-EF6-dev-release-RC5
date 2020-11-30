using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CasePhoneLocationFacade
    {
        #region Private Members

        /// <summary>
        /// The repository
        /// </summary>
        private CasePhoneLocationRepository repository = new CasePhoneLocationRepository();

        #endregion

        #region Public Methods

        /// <summary>
        /// Gets the specified case id.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public CasePhoneLocation Get(int caseId)
        {
            return repository.Get(caseId);

        }

        /// <summary>
        /// Gets the by inbound call id.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <returns></returns>
        public CasePhoneLocation GetByInboundCallId(int inboundCallId)
        {
            return repository.GetByInboundCallId(inboundCallId);

        }

        /// <summary>
        /// Gets the specified case ID.
        /// </summary>
        /// <param name="caseID">The case ID.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <returns></returns>
        public CasePhoneLocation Get(int? caseID, int? inboundCallId)
        {
            if (caseID.HasValue && caseID.Value > 0)
            {
                return repository.Get(caseID.Value);
            }
            else if (inboundCallId.HasValue && inboundCallId.Value > 0)
            {
                return repository.GetByInboundCallId(inboundCallId.Value);
            }
            else
            {
                return null;
            }
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Save(CasePhoneLocation model)
        {
            model.CreateDate = DateTime.Now;
            repository.Save(model);
        }

        #endregion

    }
}
