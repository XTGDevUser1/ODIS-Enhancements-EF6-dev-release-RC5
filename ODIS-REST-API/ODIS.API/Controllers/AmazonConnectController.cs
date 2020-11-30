using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;
using log4net;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Newtonsoft.Json;
using ODISAPI.Models;

namespace ODISAPI.Controllers {
    public class AmazonConnectController : BaseApiController {
        /// <summary>
        ///     The logger
        /// </summary>
        protected static readonly ILog logger =
            LogManager.GetLogger(typeof(AmazonConnectController));

        protected ContactLogRepository contactLogRepository =
            new ContactLogRepository();

        // POST: api/amazonconnect/ctr
        [Route("v1/amazonconnect/ctr")]
        [HttpPost]
        [ResponseType(typeof(CTRUpdateResults))]
        public HttpResponseMessage Post(List<CTRDataModel> ctrData) {
            logger.InfoFormat(
                "AmazonConnectController - Post CTR, Parameters : {0}",
                JsonConvert.SerializeObject(ctrData)
            );

            var results = new CTRUpdateResults();
            foreach (var ctrRecord in ctrData) {
                if (ctrRecord.ConnectContactID == null) {
                    results.Results.Add(
                        "UNKNOWN",
                        new CTRUpdateResult {
                            Message = "ConnectContactID Not populated!",
                            Success = false
                        });
                    continue;
                }

                bool success;
                string message;
                try {
                    var foundRecord =
                        contactLogRepository.UpdateCTRData(ctrRecord);

                    if (foundRecord == null) {
                        success = false;
                        message = "NOT_FOUND";
                    } else {
                        success = true;
                        message = string.Empty;
                    }
                } catch (Exception ex) {
                    success = false;
                    message = JsonConvert.SerializeObject(ex);
                }

                results.Results.Add(
                    ctrRecord.ConnectContactID,
                    new CTRUpdateResult {
                        Success = success,
                        Message = message
                    });
            }


            logger.InfoFormat(
                "AmazonConnectController - Post CTR, Returns : {0}",
                JsonConvert.SerializeObject(
                    new {
                        results
                    }));
            return Request.CreateResponse(HttpStatusCode.OK, results);
        }
    }
}