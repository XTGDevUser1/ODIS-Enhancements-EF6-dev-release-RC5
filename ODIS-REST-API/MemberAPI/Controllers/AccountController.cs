using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace MemberAPI.Controllers
{
    [RoutePrefix("api")]
    public class AccountController : BaseApiController
    {
        public class AccountRegister 
        {
            public string MemberNumber { get; set; }
            public string LastName { get; set; }
            public string Zip { get; set; }
        }


        [Route("v1/Account/Register")]
        [HttpPost]
        public async Task<OperationResult> Register(AccountRegister register)
        {
            var result = new OperationResult();
            result.Data = "Acccount Successfully Registered";
            return result;
        }
    }
}
