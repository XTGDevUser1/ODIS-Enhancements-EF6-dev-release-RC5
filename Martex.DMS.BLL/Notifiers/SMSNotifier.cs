using System;
using Martex.DMS.BLL.TechnoCom;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.ServiceModel;
using log4net;

namespace Martex.DMS.BLL.Communication
{
    /// <summary>
    /// SMSNotifier
    /// </summary>
    public class SMSNotifier: INotifier
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(SMSNotifier));
        #region INotifier Members

        /// <summary>
        /// Notifiers the specified communication queue.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        /// <exception cref="System.Exception"></exception>
        public void Notify(DAL.CommunicationQueue communicationQueue)
        {
            EndpointAddress WSAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.SMS_SERVICE_URI));
            BasicHttpBinding WSBinding = new BasicHttpBinding();

            LocationRequestSoapClient locationRequestSoapclient = new LocationRequestSoapClient(WSBinding, WSAddress);   
            SendSMSMessageResult result = locationRequestSoapclient.SendSMSMessage(AppConfigRepository.GetValue(AppConfigConstants.SMS_SERVICE_GUID), communicationQueue.NotificationRecipient.Replace(" ",string.Empty), communicationQueue.MessageText);
            logger.InfoFormat("Sent an sms to {0} and the status is {1}", result.tn, result.SendSMSRequestErrorCode + ": " + result.ErrorMessage);
            if ((Convert.ToInt32("0" + result.SendSMSRequestErrorCode) != 0) || (Convert.ToInt32("0" + result.StatusRequestErrorCode) != 0) )
            {
                throw new Exception(result.SendSMSRequestErrorCode + ": " + result.ErrorMessage);
            }
            
        }

        #endregion
    }
}
