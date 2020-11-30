using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{

    public class DigitalDispatchHeaderModel
    {
        public string HeaderVersion { get; set; }
        public string Key { get; set; }
        public string ContractorID { get; set; }
        public string ResponseID { get; set; }
        public string TransType { get; set; }
        public string MsgVersion { get; set; }
        public string ConRequired { get; set; }
        public string ResponseType { get; set; }
    }

    public class DigitalDispatchReturnModel
    {
        public string Request { get; set; }
        public string Response { get; set; }
    }

}
