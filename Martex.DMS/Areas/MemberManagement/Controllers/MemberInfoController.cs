using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public partial class MemberController
    {
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.Prefix, true)]
        [ReferenceDataFilter(StaticData.Suffix, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _Member_Info(int memberID, int memberShipID)
        {
            logger.InfoFormat("Loading Member Info Details Tab with Member ID {0}", memberID);
            var facade = new MemberManagementFacade();
            MemberInfoDetails model = facade.GetMemberInfoDetails(memberID);
            logger.InfoFormat("Retrieving Finished for Member ID {0}", memberID);
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(model.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the member info details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveMemberInfoDetails(MemberInfoDetails model)
        {
            logger.Info("Inside Save member info details");
            OperationResult result = new OperationResult();
            var facade = new MemberManagementFacade();
            facade.SaveMemberInfoDetails(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save for Member Information");
            return Json(result);
        }
    }
}
