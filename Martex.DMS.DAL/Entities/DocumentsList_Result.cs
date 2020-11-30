using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    public partial class DocumentsList_Result
    {
        public bool ContentFromFileSystem { get; set; }
        public string ContentPath { get; set; }
        public string DocumentType { get; set; }
    }
}
