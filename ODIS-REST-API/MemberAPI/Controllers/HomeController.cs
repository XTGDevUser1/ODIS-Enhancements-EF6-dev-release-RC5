using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace MemberAPI.Controllers
{    
    [RoutePrefix("api")]
    public class HomeController : BaseApiController
    {
        [Route("v1/Home/{id}")]    
        [HttpGet]
        public string Print(int id)
        {
            return id.ToString();
        }
    }
}
