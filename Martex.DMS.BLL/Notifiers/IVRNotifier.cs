using System;
using System.Collections.Generic;
using log4net;
using System.Net;
using System.IO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Collections;

namespace Martex.DMS.BLL.Communication
{
    /// <summary>
    /// IVRNotifier
    /// </summary>
    public class IVRNotifier : INotifier
    {
        protected static ILog logger = LogManager.GetLogger(typeof(IVRNotifier));
        protected static List<string> UrlsToBeCalled = new List<string>();
        protected string postData = "POID={0}&PHNUM={1}&LANGUAGE=E&EntryID=DMS_{2}";

        protected static string serviceUserName = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_ACCOUNT_USERNAME);
        protected static string servicePassword = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_ACCOUNT_PASSWORD);
        protected static string serviceDomain = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_ACCOUNT_DOMAIN);
        protected static int timeout = 10000; // Default value in milliseconds

        /// <summary>
        /// Initializes the <see cref="IVRNotifier"/> class.
        /// </summary>
        static IVRNotifier()
        {
            string sTimeout = AppConfigRepository.GetValue(AppConfigConstants.PHONE_HTTP_REQUEST_TIMEOUT);
            int.TryParse(sTimeout, out timeout);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="IVRNotifier"/> class.
        /// </summary>
        public IVRNotifier()
        {

        }
        /// <summary>
        /// Notifies the specified communication queue.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        /// <exception cref="DMSException">Phone HTTP Trigger urls are not set up in the system</exception>
        public void Notify(DAL.CommunicationQueue communicationQueue)
        {
            if (UrlsToBeCalled.Count == 0)
            {
                string urls = AppConfigRepository.GetValue(AppConfigConstants.PHONE_HTTP_TRIGGER);
                if (string.IsNullOrEmpty(urls))
                {
                    throw new DMSException("Phone HTTP Trigger urls are not set up in the system");
                }
                string[] urlTokens = urls.Split('|');

                UrlsToBeCalled = GetUrlsToBeInvokedAsList(urlTokens);
            }
            DateTime rStart = DateTime.Now, rEnd;

            try
            {
                var url = UrlsToBeCalled[0];
                //Remove the country code from the phone number before sending to IVR!!
                postData = string.Format(postData, string.Empty, communicationQueue.NotificationRecipient.Substring(communicationQueue.NotificationRecipient.IndexOf(" ") + 1), communicationQueue.ContactLogID);

                if (!string.IsNullOrEmpty(communicationQueue.MessageData))
                {
                    Hashtable messageDataParams = communicationQueue.XMLToKeyValuePairs(communicationQueue.MessageData);
                    if (messageDataParams.ContainsKey("ScriptNum"))
                    {
                        var scriptNum = messageDataParams["ScriptNum"].ToString();
                        logger.InfoFormat("Appending ScriptNum {0}", scriptNum);
                        postData += "&SCRIPTNUM=" + scriptNum;
                    }
                    else
                    {
                        postData += "&SCRIPTNUM=";
                    }
                }
                NetworkCredential credentials = new NetworkCredential(serviceUserName, servicePassword, serviceDomain);
                rStart = DateTime.Now;
                HttpWebResponse response = DoRequest(url, null, "GET", postData, true, credentials);
                rEnd = DateTime.Now;
                logger.InfoFormat("Invoked {0} with postData = {1} and the status = {2}", url, postData, response.StatusCode.ToString());
                logger.InfoFormat("Length of the HTTP Call : {0}ms", (rEnd - rStart).TotalMilliseconds);

                response.Close();

            }
            catch (Exception ex)
            {
                rEnd = DateTime.Now;
                logger.InfoFormat("Length of the HTTP Call : {0}ms", (rEnd - rStart).TotalMilliseconds);
                logger.Error(ex.Message, ex);
                throw ex;
            }
            finally
            {
                UrlsToBeCalled.RemoveAt(0);
            }

        }

        /// <summary>
        /// Gets the urls to be invoked as list.
        /// </summary>
        /// <param name="urlTokens">The URL tokens.</param>
        /// <returns></returns>
        private static List<string> GetUrlsToBeInvokedAsList(string[] urlTokens)
        {
            List<string> urlsToBeInvoked = new List<string>();
            foreach (string token in urlTokens)
            {
                if (!urlsToBeInvoked.Contains(token))
                {
                    urlsToBeInvoked.Add(token);
                }
            }

            return urlsToBeInvoked;
        }

        /// <summary>
        /// Does the request.
        /// </summary>
        /// <param name="url">The URL.</param>
        /// <param name="cookies">The cookies.</param>
        /// <param name="requestMethod">The request method.</param>
        /// <param name="postData">The post data.</param>
        /// <param name="autoRedirect">if set to <c>true</c> [auto redirect].</param>
        /// <param name="credentials">The credentials.</param>
        /// <returns></returns>
        static HttpWebResponse DoRequest(string url, CookieCollection cookies, string requestMethod, string postData, bool autoRedirect, NetworkCredential credentials)
        {

            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url + postData);
            request.Method = requestMethod;
            request.ContentType = "application/x-www-form-urlencoded";
            request.AllowAutoRedirect = autoRedirect;
            request.UserAgent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.8) Gecko/2009032609 Firefox/3.0.8";
            request.KeepAlive = false;

            request.Timeout = timeout;

            if (credentials != null)
            {
                request.Credentials = credentials;
            }

            request.CookieContainer = new CookieContainer();

            if (cookies != null)
            {
                request.CookieContainer.Add(new Uri(url), cookies);
            }
            return request.GetResponse() as HttpWebResponse;
        }


        /// <summary>
        /// Gets the response as string.
        /// </summary>
        /// <param name="response">The response.</param>
        /// <returns></returns>
        static string GetResponseAsString(HttpWebResponse response)
        {
            using (StreamReader reader = new StreamReader(response.GetResponseStream()))
            {
                return reader.ReadToEnd();
            }
        }

    }
}
