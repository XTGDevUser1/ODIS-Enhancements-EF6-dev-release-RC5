using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using ClientPortal.Common;
//using Telerik.Web.Mvc;

namespace ClientPortal.Areas.Common.Controllers
{
    public class PhoneController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Get the Phone Details
        /// </summary>
        /// <param name="recordId"></param>
        /// <returns></returns>
        //[GridAction]
        public ActionResult _SelectPhoneDetails(string recordId)
        {
            var phoneRepository = new PhoneRepository();
            int iRecordId = 0;
            List<PhoneEntity> phoneDetails = null;
            int.TryParse(recordId, out iRecordId);
            if (iRecordId > 0)
            {
                phoneDetails = phoneRepository.GetPhoneDetails(iRecordId);
            }
            if (phoneDetails != null)
            {
                return Json(phoneDetails.Select(x => new
                {
                    PhoneType = new { ID = x.PhoneType.ID, Name = x.PhoneType.Name },
                    x.ID,
                    x.PhoneNumber                    
                }));
            }
            return Json(new List<AddressEntity>());
        }
        
        /// <summary>
        /// Get the Phone Types
        /// </summary>
        /// <param name="entityType"></param>
        /// <returns></returns>
        public ActionResult _SelectPhoneTypes(string entityType)
        {
            var phoneTypes = ReferenceDataRepository.GetPhoneTypes(entityType).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(phoneTypes);
        }
        #endregion
    }
}
