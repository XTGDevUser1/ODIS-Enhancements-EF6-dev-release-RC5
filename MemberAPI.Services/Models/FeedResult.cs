using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{
    public class WPGuid
    {
        public string Rendered { get; set; }
    }

    public class WPTitle
    {
        public string Rendered { get; set; }
    }

    public class WPContent
    {
        public string Rendered { get; set; }
    }

    public class WPExcerpt
    {
        public string Rendered { get; set; }
    }

    public class WPSelf
    {
        public string Href { get; set; }
    }

    public class WPCollection
    {
        public string Href { get; set; }
    }

    public class WPAbout
    {
        public string Href { get; set; }
    }

    public class WPAuthor
    {
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPReply
    {
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPVersionHistory
    {
        public string Href { get; set; }
    }

    public class WPFeaturedmedia
    {
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPAttachment
    {
        public string Href { get; set; }
    }

    public class WPTerm
    {
        public string Taxonomy { get; set; }
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPCury
    {
        public string Name { get; set; }
        public string Href { get; set; }
        public bool Templated { get; set; }
    }

    public class WPLinks
    {
        public List<WPSelf> Self { get; set; }
        public List<WPCollection> Collection { get; set; }
        public List<WPAbout> About { get; set; }
        public List<WPAuthor> Author { get; set; }
        public List<WPReply> Replies { get; set; }
        [JsonProperty("version-history")]
        public List<WPVersionHistory> VersionHistory { get; set; }
        [JsonProperty("wp:featuredmedia")]
        public List<WPFeaturedmedia> WPFeaturedmedia { get; set; }
        [JsonProperty("wp:attachment")]
        public List<WPAttachment> WPAttachment { get; set; }
        [JsonProperty("wp:term")]
        public List<WPTerm> WPTerm { get; set; }
        public List<WPCury> Curies { get; set; }
    }

    public class FeedResult
    {
        public int Id { get; set; }
        public string Date { get; set; }
        [JsonProperty("date_gmt")]
        public string DateGMT { get; set; }
        public WPGuid Guid { get; set; }
        public string Modified { get; set; }
        [JsonProperty("modified_gmt")]
        public string ModifiedGMT { get; set; }
        public string Slug { get; set; }
        public string Type { get; set; }
        public string Link { get; set; }
        public WPTitle Title { get; set; }
        public WPContent Content { get; set; }
        public WPExcerpt Excerpt { get; set; }
        public int Author { get; set; }
        [JsonProperty("featured_media")]
        public int FeaturedMedia { get; set; }
        [JsonProperty("comment_status")]
        public string CommentStatus { get; set; }
        [JsonProperty("ping_status")]
        public string Ping_Status { get; set; }
        public bool Sticky { get; set; }
        public string Format { get; set; }
        public List<int> Categories { get; set; }
        public List<object> Tags { get; set; }
        [JsonProperty("_links")]
        public WPLinks Links { get; set; }
        public string ImagePath { get; set; }
    }
}
