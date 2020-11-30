using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using Newtonsoft.Json;
using System.Diagnostics;
using System.Threading;
using ODISMember.Entities;
using ODISMember.Services.Service;

namespace ODISMember.Services
{
    public static class RestManager
    {
        public async static Task<string> CallRestService(string url, string method, Dictionary<string, object> parameters, Dictionary<string, object> headers = null, string contentType = "application/json")
        {
            try
            {
                if (Constants.IS_CONNECTED)
                {

                    // Create an HTTP web request using the URL:
                    string formattedParams = string.Empty;

                    if ((string.Equals(HttpMethods.GET.ToString(), method) || string.Equals(HttpMethods.DELETE.ToString(), method)) && parameters != null && parameters.Count() > 0)
                    {
                        formattedParams = string.Join("&", parameters.Select(x => x.Key + "=" + System.Net.WebUtility.UrlEncode(x.Value.ToString())));
                        url = string.Format("{0}?{1}", url, formattedParams);
                    }
                    else if ((string.Equals(HttpMethods.POST.ToString(), method) || string.Equals(HttpMethods.PUT.ToString(), method)) && parameters != null && parameters.Count() > 0)
                    {
                        if (parameters != null && parameters.Count() > 0)
                        {
                            if ("application/json".Equals(contentType))
                            {
                                formattedParams = JsonConvert.SerializeObject(parameters.FirstOrDefault().Value);
                            }
                            else
                            {
                                formattedParams = string.Join("&", parameters.Select(x => x.Key + "=" + x.Value));
                            }
                        }
                    }

                    HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(new Uri(url));

                    request.Accept = "application/json";

                    if (headers == null)
                    {
                        headers = new Dictionary<string, object>();
                    }

                    if (!string.IsNullOrEmpty(Constants.ACCESS_TOKEN))
                    {
                        headers.Add("Authorization", "Bearer " + Constants.ACCESS_TOKEN);
                    }
                    if (!string.IsNullOrEmpty(Constants.X_API_KEY))
                    {
                        headers.Add("X-APIKEY", Constants.X_API_KEY);
                    }
                    if (!string.IsNullOrEmpty(Constants.ORGANIZATION_ID))
                    {
                        headers.Add("OrganizationID", Constants.ORGANIZATION_ID);
                    }

                    if (headers != null)
                    {
                        foreach (KeyValuePair<string, object> kvp in headers)
                        {
                            request.Headers[kvp.Key] = kvp.Value.ToString();
                        }
                    }
                    request.Method = method;
                    //Debug.WriteLine("Url = "+url+" formattedParams =" + formattedParams);
                    if (string.Equals(HttpMethods.POST.ToString(), method) || string.Equals(HttpMethods.PUT.ToString(), method))
                    {
                        if (parameters.Count > 0)
                        {
                            request.ContentType = contentType;
                            Stream stream = await request.GetRequestStreamAsync();

                            using (StreamWriter writer = new StreamWriter(stream))
                            {
                                writer.Write(formattedParams);
                                writer.Flush();
                                //writer.Dispose ();
                            }
                        }
                    }

                    WebResponse response = await Task.Factory.FromAsync<WebResponse>(request.BeginGetResponse, request.EndGetResponse, request);
                    using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                    {
                        string res = reader.ReadToEnd();
                        return res;
                    }
                }
                else
                {
                    if (url == RestAPI.URL_LOGIN)
                    {

                        AccessResult accessResult = new AccessResult();
                        accessResult.access_token = null;
                        accessResult.error_description = "Connection lost. Please check your internet connection.";
                        return JsonConvert.SerializeObject(accessResult);
                    }
                    else
                    {
                        OperationResult operationResult = new OperationResult();
                        operationResult.Status = OperationStatus.ERROR;
                        operationResult.ErrorMessage = "Connection lost. Please check your internet connection.";
                        return JsonConvert.SerializeObject(operationResult);
                    }
                }
            }
            catch (WebException ex)
            {
                var httpResponse = ex.Response;
             
                if (httpResponse != null)
                {
                    var webresponse = httpResponse as System.Net.HttpWebResponse;
                    //checking for unauthorized status. If user not authorized to access the resource app will prompt user to re-login
                    //Possible Scenario: Token expiry 
                    if (webresponse != null)
                    {
                        if (webresponse.StatusCode == HttpStatusCode.Unauthorized)
                        {
                            OperationResult operationResult = new OperationResult();
                            operationResult.Status = OperationStatus.ERROR;
                            operationResult.ErrorMessage = "Token expired. Please logout and login again.";

                            return JsonConvert.SerializeObject(operationResult);

                        }
                        //else
                        //{
                        //    OperationResult operationResult = new OperationResult();
                        //    operationResult.Status = OperationStatus.ERROR;
                        //    operationResult.ErrorMessage = webresponse.StatusDescription;
                        //    return JsonConvert.SerializeObject(operationResult);
                        //}
                    }
                }
                //if (RestAPI.URL_MOBILE_WORD_PRESS_POSTS == url)
                //{
                //    return string.Empty;
                //}
                if (ex.Status == WebExceptionStatus.ConnectFailure)
                {
                    if (httpResponse != null && httpResponse.GetResponseStream() != null)
                    {
                        using (StreamReader reader = new StreamReader(httpResponse.GetResponseStream()))
                        {
                            var resString = reader.ReadToEnd();
                            return resString;
                        }
                    }
                }
                if (url == RestAPI.URL_LOGIN)
                {
                    if (httpResponse != null && httpResponse.GetResponseStream() != null)
                    {
                        using (StreamReader reader = new StreamReader(httpResponse.GetResponseStream()))
                        {
                            var resString = reader.ReadToEnd();
                            return resString;
                        }
                    }
                    AccessResult accessResult = new AccessResult();
                    accessResult.access_token = null;
                    accessResult.error_description = "Unable to reach server. Please try again later.";

                    return JsonConvert.SerializeObject(accessResult);
                }
                else
                {

                    //if (httpResponse != null && httpResponse.GetResponseStream() != null)
                    //{
                    //    using (StreamReader reader = new StreamReader(httpResponse.GetResponseStream()))
                    //    {
                    //        var resString = reader.ReadToEnd();
                    //        return resString;
                    //    }
                    //}

                    OperationResult operationResult = new OperationResult();
                    operationResult.Status = OperationStatus.ERROR;
                    operationResult.ErrorMessage = "We are Unable to process your request at this time. Please try again later.";
                    return JsonConvert.SerializeObject(operationResult);
                }
            }
        }

        private static async Task<string> GetResponseString(HttpWebRequest request)
        {
            WebResponse response =
                await
                Task.Factory.FromAsync<WebResponse>(request.BeginGetResponse, request.EndGetResponse,
                    request);
            using (StreamReader reader = new StreamReader(response.GetResponseStream()))
            {
                return reader.ReadToEnd();
            }
        }
    }
}



