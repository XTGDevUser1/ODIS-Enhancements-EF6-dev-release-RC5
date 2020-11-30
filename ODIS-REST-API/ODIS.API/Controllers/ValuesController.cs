using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace ODISAPI.Controllers
{
    public class GetModel
    {
        public string ID { get; set; }
        public string Name { get; set; }
    }
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
        //[Authorize]
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
        public void Post([FromBody]string value)
        {
        }

        // PUT api/values/5
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE api/values/5
        public void Delete(int id)
        {
        }

        [Route("servicerequest/{id}/cancel")]
        [HttpGet]
        public int Cancel(int id)
        {
            return id;
        }
    }
}
