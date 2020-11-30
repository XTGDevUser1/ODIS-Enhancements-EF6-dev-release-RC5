using MemberAPI.DAL.CustomEntities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;

namespace MemberAPI.Controllers
{
    public class GetModel
    {
        public string ID { get; set; }
        public string Name { get; set; }
    }
    
    [ApiExplorerSettings(IgnoreApi = true)]
    [RoutePrefix("api")]
    public class ValuesController : BaseApiController
    {
        // GET api/values
        //[Authorize]
        //public IEnumerable<string> Get()
        //{

        //    return new string[] { "value1", "value2", AuthenticatedUserName };
        //}

        // GET api/values/5
        
        [Route("v1/values")]
        public string Get([FromUri] GetModel model)
        {
            return "value";
        }

        [Route("v1/values/{id}")]
        public string Get(int id)
        {
            return "ID";
        }

        // POST api/values
        [Route("v1/values/Process")]
        [HttpPost]
        public OperationResult Process([FromBody]MemberModel value)
        {
            return new OperationResult();
        }

        // POST api/values
        [Route("v1/values/Join")]
        [HttpPost]
        public OperationResult Join([FromBody]MemberModel value)
        {
            return new OperationResult();
        }

        // PUT api/values/5
        public void Put(int id, [FromBody]MemberModel value)
        {
        }

        // DELETE api/values/5
        public void Delete(int id)
        {
        }
    }
}
