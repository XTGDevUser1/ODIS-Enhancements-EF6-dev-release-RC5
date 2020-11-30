using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.ServiceModel;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using log4net;
using System.Net;
using System.Net.Security;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class ClickToCallFacade
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(ClickToCallFacade));

        /// <summary>
        /// Calls the specified phone number.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <exception cref="DMSException"></exception>
        public static void Call(ClickToCallModel model)
        {
            EventLoggerFacade facade = new EventLoggerFacade();
            string callstatus = "SUCCESS";
            string callFailureDetails = string.Empty;
            try
            {

                MakeACall(model.PhoneNumber, model.DeviceName, model.PhoneUserId, model.PhonePassword);
            }
            catch (Exception ex)
            {
                logger.Warn(ex);
                callstatus = "FAILURE";
                callFailureDetails = ex.StackTrace;
            }
            string eventDetail = string.Format("<EventDetail><Result>{0}</Result><PhoneNumber>{1}</PhoneNumber><ErrorDescription>{2}</ErrorDescription></EventDetail>",callstatus,model.PhoneNumber,callFailureDetails);
            facade.LogEvent(model.EventSource, EventNames.CLICK_TO_CALL, eventDetail, model.CurrentUser, model.UserId,EntityNames.USER,model.SessionID);
            logger.InfoFormat("Event log created successfully after making a call and callstatus : {0}", callstatus);

            if (callstatus == "FAILURE")
            {
                throw new DMSException(callFailureDetails);
            }
        }

        /// <summary>
        /// Makes A call.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="deviceName">Name of the device.</param>
        /// <param name="phoneUserId">The phone user id.</param>
        /// <param name="phonePassword">The phone password.</param>
        /// <exception cref="DMSException">
        /// </exception>
        private static void MakeACall(string phoneNumber, string deviceName, string phoneUserId, string phonePassword)
        {
            EndpointAddress WSAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.WEB_DIALER_URI));

            logger.InfoFormat("Click-to-call invoked with the following parametes - {0}, {1}, {2}, {3}", phoneNumber, deviceName, phoneUserId, phonePassword);
          
            #region BasicHttpBinding
            
            BasicHttpBinding WSBinding = new BasicHttpBinding
            {
                Name = "WSBinding",
                    CloseTimeout = TimeSpan.FromMinutes(1.0),
                    HostNameComparisonMode = HostNameComparisonMode.StrongWildcard,
                    MessageEncoding = WSMessageEncoding.Text,
                    MaxReceivedMessageSize = 65536000,
                    MaxBufferPoolSize = 65536000,
                    UseDefaultWebProxy = true,
                    AllowCookies = false,
                    BypassProxyOnLocal = false,
                    Security =
                {
                    Mode =BasicHttpSecurityMode.Transport,
                    Transport =
                    {
                        ClientCredentialType = HttpClientCredentialType.None,
                        ProxyCredentialType = HttpProxyCredentialType.None
                    },
                    Message =
                        {
                            ClientCredentialType = BasicHttpMessageCredentialType.UserName
                        }
                } 
            };

            #endregion

            WebDialerService.WDSoapInterfaceClient svc = new WebDialerService.WDSoapInterfaceClient(WSBinding, WSAddress);
            WebDialerService.Credential cred = new WebDialerService.Credential();
            WebDialerService.ConfigResponseDetail confResponseDetail = default(WebDialerService.ConfigResponseDetail);

            string errorMessage = string.Empty;
            string phonePrefix = AppConfigRepository.GetValue(AppConfigConstants.PHONE_NUMBER_PREFIX);
            
            try
            {
                cred.userID = phoneUserId;
                cred.password = phonePassword;

                //TODO:Remove the following code once SSL is set up
                ServicePointManager.ServerCertificateValidationCallback = new RemoteCertificateValidationCallback((x, certificate, chain, errors) => { return true; });
               
                confResponseDetail = svc.getProfileDetailSoap(cred);
                logger.InfoFormat("Response from Web dialer service - Code = {0}, Desc - {1}", confResponseDetail.responseCode, confResponseDetail.description);
                if (confResponseDetail.description.ToUpper() != "SUCCESS")
                {
                    //**Log failure and disable click to call for the user's session
                    errorMessage = "Unable to validate credentials";
                    logger.InfoFormat(errorMessage);
                    throw new DMSException(errorMessage);

                }

                WebDialerService.UserProfile upr = new WebDialerService.UserProfile();

                upr.deviceName = deviceName;
                //**Coming from session, read by java applet from registry
                upr.lineNumber = "1";
                //**Hardcoded to 1 for now
                upr.user = phoneUserId;
                //**User.PhoneUserID field

                WebDialerService.CallResponse callRes = default(WebDialerService.CallResponse);
               
                callRes = svc.makeCallSoap(cred, phonePrefix + phoneNumber.Replace(" ",string.Empty), upr);
                //**Replace "18175488540" with phone number to dial without the extension, they will manually type in extension once call goes through.  The ‘9’ Prefix comes from the ApplicationConfiguration table (Name = ‘PhoneNumberPrefix’)

                //**0 = SUCCESS
                if (callRes.responseCode != 0)
                {
                    //**Log Failure and the reason for failure, throw exception and notify user of the failure so they can manually make the phone call
                    errorMessage = "Unable to connect call: " + callRes.responseDescription;
                    logger.InfoFormat(errorMessage);
                    throw new DMSException(errorMessage);
                }

            }
            catch (DMSException dex)
            {
                throw dex;
            }
            catch (Exception ex)
            {
                logger.Warn(ex.Message, ex);
                throw ex;
            }
        }
    }
}
