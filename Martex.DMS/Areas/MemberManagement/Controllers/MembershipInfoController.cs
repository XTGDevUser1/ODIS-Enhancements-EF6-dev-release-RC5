using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
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
        public ActionResult _Membership_Info(int membershipID)
        {
            logger.InfoFormat("Loading Membership Info Details Tab with Membership ID {0}", membershipID);
            var facade = new MemberManagementFacade();
            MemberShipInfoDetails info = facade.GetMemberShipInfoDetails(membershipID);
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(info.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);
            logger.Info("Finished execution");
            return PartialView(info);
        }


       

        /// <summary>
        /// Saves the membership info details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveMembershipInfoDetails(MemberShipInfoDetails model)
        {
            logger.Info("Inside Save membership info details");
            OperationResult result = new OperationResult();
            var facade = new MemberManagementFacade();
            facade.SaveMembershipInfoDetails(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save for Membership Information");
            return Json(result);
        }
    }
}
