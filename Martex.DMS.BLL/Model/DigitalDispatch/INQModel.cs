using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class INQModel : DigitalDispatchHeaderModel
    {
        public string QueryType { get; set; }
        public string ResultType { get; set; }
        public string ResultArrayName { get; set; }
    }
}
