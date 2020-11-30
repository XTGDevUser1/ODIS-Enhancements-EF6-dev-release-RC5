using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class UPDModel : DigitalDispatchHeaderModel
    {
        public string KeyElementName { get; set; }
        public string ElementName { get; set; }
        public string OldValue { get; set; }
        public string NewValue { get; set; }
    }
}
