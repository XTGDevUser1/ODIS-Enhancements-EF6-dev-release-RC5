using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class ERRModel : DigitalDispatchHeaderModel
    {
        public string ErrorCode { get; set; }
        public string ErrorDescription { get; set; }
    }
}
