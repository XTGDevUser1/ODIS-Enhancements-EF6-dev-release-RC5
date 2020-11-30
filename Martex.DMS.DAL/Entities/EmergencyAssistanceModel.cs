using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;

namespace Martex.DMS.DAL.Entities
{
    public class EmergencyAssistanceModel
    {
        public int? CallBackNumberType { get; set; }
        public string CallBackNumber { get; set; }
        public string SearchLocation { get; set; }
        public int ContactActionID { get; set; }
        public EmergencyAssistance EmergencyAssistance { get; set; }
        public ContactLog ContactLog { get; set; }
        public Comment Comment { get; set; }
        public CasePhoneLocation CasePhoneLocation { get; set; }
        public List<PreviousCallList> PreviousCallList { get; set; }
        // Result Type 
        // Success = 0
        // Matching entry Found but does not have any coordinates  then = 1
        // Return Result foe the Phone Number but does not have any coordinates then = 2
        // No Record Found = 3
        public PhoneLocationResultType ResultType { get; set; }
        public string ResultTypeMessage { get; set; }
        public bool ContactInsertRequired { get; set; }
    }

    public enum PhoneLocationResultType : int
    {
        SUCCESS = 0,
        ENTRY_FOUND_NO_COORDINATES = 1,
        NO_RECORDS_FOUND = 3
    }
    
}