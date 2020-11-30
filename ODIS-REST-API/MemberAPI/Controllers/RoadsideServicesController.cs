using log4net;
using MemberAPI.DAL.CustomEntities;
using MemberAPI.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace MemberAPI.Controllers
{
    [RoutePrefix("api")]
    public class RoadsideServicesController : BaseApiController
    {
        protected readonly IODISAPIService _odisService = new ODISAPIService();
        protected static readonly ILog logger = LogManager.GetLogger(typeof(RoadsideServicesController));

        [Route("v1/RoadsideServices/Questions")]
        [Authorize]
        [HttpGet]
        public OperationResult GetQuestions([FromUri] QuestionsCriteria criteria)
        {
            OperationResult result = new OperationResult();

            criteria.ProgramID = Claim_ProgramID;
            LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, QuestionCriteria = criteria });
            result.Data = _odisService.GetQuestionnaire(criteria);
            return result;
        }

        [Route("v1/RoadsideServices")]
        [Authorize]
        [HttpGet]
        public OperationResult Get()
        {
            LogAPIEvent(new { OrganizationID = OrganizationID, MembershipNumber = Claim_MemberShipNumber, ProgramID = Claim_ProgramID });
            OperationResult result = new OperationResult();
            result.Data = _odisService.GetRoadsideServices(Claim_ProgramID);
            return result;
        }
    }
}
