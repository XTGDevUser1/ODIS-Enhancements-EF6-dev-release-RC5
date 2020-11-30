using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace Martex.DMS.BLL.Model
{
    public class DocumentModel
    {
        public string EntityName { get; set; }
        public int RecordId { get; set; }
        public int DocumentType { get; set; }
        public string Comment { get; set; }
        public HttpPostedFileBase FileDocument { get; set; }
        public string DocumentCategory { get; set; }
        public string DocumentCategoryId { get; set; }
        public string SourceSystem { get; set; }
        public bool IsShownOnVendorPortal { get; set; }
        public bool IsShownOnClientPortal { get; set; }
    }
}
