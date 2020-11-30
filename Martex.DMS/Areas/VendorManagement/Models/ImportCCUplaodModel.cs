using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Areas.VendorManagement.Models
{
    public class ImportCCUplaodModel
    {
        public string FileType { get; set; }
        public string FileName { get; set; }
        public HttpPostedFileBase CCDocument { get; set; }
    }
}