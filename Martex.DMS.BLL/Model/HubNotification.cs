using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.BLL.Model
{
    public class HubNotification
    {
        public string Title { get; set; }
        public string Message { get; set; }
        [JsonProperty(PropertyName = "category")]
        public string Category { get; set; }
        public string Data { get; set; }
        [JsonProperty(PropertyName = "alert")]
        public string Alert { get; set; }

        [JsonProperty(PropertyName = "content-available")]
        public string ContentAvailable {  get { return "1"; } }
    }
}
