using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// GoToPOModel
    /// </summary>
    public class GoToPOModel
    {

        public string TalkedTo
        {
            get;
            set;
        }

        public string VendorName
        {
            get;
            set;
        }

        public string VendorSource
        {
            get;
            set;
        }

        public string PhoneType
        {
            get;
            set;
        }

        public string PhoneNumber
        {
            get;
            set;
        }

        public int? VendorLocationID
        {
            get;
            set;
        }

        public int? VendorID
        {
            get;
            set;
        }
    }
}
