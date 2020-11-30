using System;
using System.Diagnostics;
using Martex.DMS.DAL;
using log4net;
using System.Net.Http;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;

namespace Martex.DMS.BLL.Communication
{
    public class AmazonConnectNotifier : INotifier
    {
        protected static ILog logger = LogManager.GetLogger(typeof(AmazonConnectNotifier));

        public void Notify(CommunicationQueue communicationQueue)
        {
            logger.InfoFormat("Initiating outbound call for contactLog ID : {0}", communicationQueue.ContactLogID);

            var appConfigRepository = new AppConfigRepository();
            var appConfigKeysForOutboundCall = appConfigRepository.GetApplicationConfigurationList(AppConfigConstants.APPLICATION_CONFIGURATION_TYPE_COM_QUEUE, AppConfigConstants.CLOSED_LOOP_SERVICE_CATEGORY);


            var apiHost = appConfigKeysForOutboundCall.Where(x => x.Name == AppConfigConstants.OutboundCallAPIHost).FirstOrDefault();
            apiHost.ThrowExceptionIfNull(string.Format("Missing configuration item - {0} ", AppConfigConstants.OutboundCallAPIHost));

            var apiEndPoint = appConfigKeysForOutboundCall.Where(x => x.Name == AppConfigConstants.OutboundCallAPIEndpoint).FirstOrDefault();
            apiEndPoint.ThrowExceptionIfNull(string.Format("Missing configuration item - {0} ", AppConfigConstants.OutboundCallAPIEndpoint));

            var apiKey = appConfigKeysForOutboundCall.Where(x => x.Name == AppConfigConstants.OutboundCallApiKey).FirstOrDefault();
            apiKey.ThrowExceptionIfNull(string.Format("Missing configuration item - {0} ", AppConfigConstants.OutboundCallApiKey));

            string queueID;
            if (!String.IsNullOrWhiteSpace(communicationQueue.QueueARN)
            ) {
                logger.InfoFormat("Using QueueARN : {0}", communicationQueue.QueueARN);
                queueID = ParseQueueID(communicationQueue.QueueARN);
                logger.InfoFormat("Using QueueID : {0}", queueID);
            } else {
                var queueConfig = appConfigKeysForOutboundCall.Where(x => x.Name == AppConfigConstants.OutboundCallQueueID).FirstOrDefault();
                queueConfig.ThrowExceptionIfNull(string.Format("Missing configuration item - {0} ", AppConfigConstants.OutboundCallQueueID));
                queueID = queueConfig.Value;
                logger.InfoFormat("Using Default QueueID : {0}", queueID);
            }


            var contactFlowID = appConfigKeysForOutboundCall.Where(x => x.Name == AppConfigConstants.OutboundCallContactFlowID).FirstOrDefault();
            contactFlowID.ThrowExceptionIfNull(string.Format("Missing configuration item - {0} ", AppConfigConstants.OutboundCallContactFlowID));

            HttpClient client = new HttpClient();
            client.BaseAddress = new Uri(apiHost.Value);
            client.DefaultRequestHeaders
                  .Accept
                  .Add(new MediaTypeWithQualityHeaderValue("application/json"));//ACCEPT header

            client.DefaultRequestHeaders.Add("X-Api-Key", apiKey.Value);

            HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, apiEndPoint.Value);

            var to = string.Format("+{0}", communicationQueue.NotificationRecipient.Replace(" ", string.Empty));
            var payload = string.Format("{{ \"OdisUniqueId\": \"{0}\", \"ContactFlowId\" : \"{1}\", \"QueueId\" : \"{2}\", \"DestinationPhoneNumber\" : \"{3}\" ,\"ServiceRequestID\": \"{4}\" }}",
                communicationQueue.ContactLogID,
                contactFlowID.Value,
                queueID,
                to,
                communicationQueue.ServiceRequestID);

            logger.InfoFormat("About to call Amazon Connect API with payload : {0}", payload);
            request.Content = new StringContent(payload,
                                                Encoding.UTF8,
                                                "application/json");//CONTENT-TYPE header

            var response = client.SendAsync(request).GetAwaiter().GetResult();
            logger.InfoFormat("Response status from Outbound Call API :: {0}", response.StatusCode);
            response.EnsureSuccessStatusCode();

            var responseAsString = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
            logger.InfoFormat("Response from Outbound call API :: {0}", responseAsString);

            return;
        }

        private string ParseQueueID(string queueArn) {
            var pos = queueArn.LastIndexOf("/") + 1;
            return queueArn.Substring(pos);
        }

    }
}