using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class WPMGuid
    {
        public string Rendered { get; set; }
    }

    public class WPMTitle
    {
        public string Rendered { get; set; }
    }

    public class WPMThumbnail
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMMedium
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMEtPbPostMainImage
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMEtPbPortfolioImage
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMEtPbPortfolioModuleImage
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMFull
    {
        public string File { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("source_url")]
        public string SourceURL { get; set; }
    }

    public class WPMSizes
    {
        public WPMThumbnail Thumbnail { get; set; }
        public WPMMedium Medium { get; set; }
        [JsonProperty("et-pb-post-main-image")]
        public WPMEtPbPostMainImage EtPbPostMainImage { get; set; }
        [JsonProperty("et-pb-portfolio-image")]
        public WPMEtPbPortfolioImage EtPbPortfolioImage { get; set; }
        [JsonProperty("et-pb-portfolio-module-image")]
        public WPMEtPbPortfolioModuleImage EtPbPortfolioModuleImage { get; set; }
        public WPMFull Full { get; set; }
    }

    public class WPMImageMeta
    {
        public string Aperture { get; set; }
        public string Credit { get; set; }
        public string Camera { get; set; }
        public string Caption { get; set; }
        public string Created_timestamp { get; set; }
        public string Copyright { get; set; }
        [JsonProperty("focal_length")]
        public string FocalLength { get; set; }
        public string ISO { get; set; }
        [JsonProperty("shutter_speed")]
        public string ShutterSpeed { get; set; }
        public string Title { get; set; }
        public string Orientation { get; set; }
    }

    public class WPMMediaDetails
    {
        public int Width { get; set; }
        public int Height { get; set; }
        public string File { get; set; }
        public WPMSizes Sizes { get; set; }
        [JsonProperty("image_meta")]
        public WPMImageMeta ImageMeta { get; set; }
    }

    public class WPMSelf
    {
        public string Href { get; set; }
    }

    public class WPMCollection
    {
        public string Href { get; set; }
    }

    public class WPMAbout
    {
        public string Href { get; set; }
    }

    public class WPMAuthor
    {
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPMReply
    {
        public bool Embeddable { get; set; }
        public string Href { get; set; }
    }

    public class WPMLinks
    {
        public List<WPMSelf> self { get; set; }
        public List<WPMCollection> collection { get; set; }
        public List<WPMAbout> about { get; set; }
        public List<WPMAuthor> author { get; set; }
        public List<WPMReply> replies { get; set; }
    }

    public class WPMediaResult
    {
        public int Id { get; set; }
        public string Date { get; set; }
        [JsonProperty("date_gmt")]
        public string DateGMT { get; set; }
        public WPMGuid Guid { get; set; }
        public string Modified { get; set; }
        [JsonProperty("modified_gmt")]
        public string ModifiedGMT { get; set; }
        public string Slug { get; set; }
        public string Sype { get; set; }
        public string Link { get; set; }
        public WPMTitle Title { get; set; }
        public int Author { get; set; }
        [JsonProperty("comment_status")]
        public string CommentStatus { get; set; }
        [JsonProperty("ping_status")]
        public string PingStatus { get; set; }
        [JsonProperty("alt_text")]
        public string AltText { get; set; }
        public string Caption { get; set; }
        public string Description { get; set; }
        [JsonProperty("media_type")]
        public string MediaType { get; set; }
        [JsonProperty("mime_type")]
        public string MimeType { get; set; }
        [JsonProperty("media_details")]
        public WPMMediaDetails MediaDetails { get; set; }
        public int Post { get; set; }
        [JsonProperty("source_url")]
        public string SourceUrl { get; set; }
        [JsonProperty("_links")]
        public WPMLinks Links { get; set; }
    }
}
