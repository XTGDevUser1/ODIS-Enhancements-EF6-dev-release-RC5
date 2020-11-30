using MemberAPI.Services.Models;
using Newtonsoft.Json;
using RestSharp;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public class WordPressFeedService : IFeedService
    {
        #region App Settings
        const string WORD_PRESS_FEED_END_POINT = "WordPressFeedEndPoint";
        #endregion

        public List<FeedResult> GetFeeds()
        {
            string endPoint = ConfigurationManager.AppSettings[WORD_PRESS_FEED_END_POINT];
            var posts = Execute<List<FeedResult>>(endPoint, Method.GET);

            for (int i = 0, pCount = posts.Count; i < pCount; i++)
            {
                var post = posts[i];
                if (post.Links != null && post.Links.WPAttachment != null && post.Links.WPAttachment.Count > 0)
                {
                    var wpMedia = GetFeedMedia(post.Links.WPAttachment[0].Href);
                    if (wpMedia != null)
                    {
                        //post.ImagePath = wpMedia != null && wpMedia.MediaDetails != null && wpMedia.MediaDetails.Sizes != null && wpMedia.MediaDetails.Sizes.Full != null ? wpMedia.MediaDetails.Sizes.Full.SourceURL : "";
                        post.ImagePath = wpMedia != null ? wpMedia.SourceUrl : "";
                        //TODO: work around for iOS. hot fix. Images are not loading over https in iOS changing https to http
                        post.ImagePath = !string.IsNullOrEmpty(post.ImagePath) ? post.ImagePath.Replace("https://", "http://") : "";
                    }
                }
            }

            return posts;
        }

        protected FeedMediaResult GetFeedMedia(string endPoint)
        {
            var mediaResults = Execute<List<FeedMediaResult>>(endPoint, Method.GET);

            return mediaResults != null && mediaResults.Count() > 0 ? mediaResults[0] : null;
        }

        protected T Execute<T>(string endPoint, Method method)
        { 
            var client = new RestClient(endPoint);
            var request = new RestRequest(method);

            request.RequestFormat = DataFormat.Json;

            IRestResponse response = client.Execute(request);

            if (response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                var result = JsonConvert.DeserializeObject<T>(response.Content);
                return result;
            }
            else
            {
                throw new MemberException(response.ErrorMessage);
            }
        }
    }
}
