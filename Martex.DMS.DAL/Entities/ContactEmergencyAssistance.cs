using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class ContactEmergencyAssistance
    {
        public string AgencyName { get; set; }
        public string OperatorPhoneNumber { get; set; }
        public string AdditonalInformation { get; set; }
        public bool ResultFound { get; set; }
        public bool IsError { get; set; }
        public string ErrorMessage { get; set; }
    }
}
