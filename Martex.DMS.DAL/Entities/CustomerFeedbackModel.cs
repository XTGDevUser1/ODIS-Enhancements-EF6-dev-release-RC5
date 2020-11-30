using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL.Entities
{
    public class CustomerFeedbackModel
    {
        public int ID { get; set; }

        public CustomerFeedback CustomerFeedback { get; set; }

        public List<CheckBoxLookUp> Statuses { get; set; }
        public List<CheckBoxLookUp> Sources { get; set; }
        public List<CheckBoxLookUp> FeedbackTypes { get; set; }
        public List<CheckBoxLookUp> Priority { get; set; }

        public string FeedbackType { get; set; }
        public int PurchaseOrderID { get; set; }

        public string ClientName { get; set; }
        public string ProgramName { get; set; }
        public string CustomerFeedbackStatusName { get; set; }

        public bool IsRecordLocked
        {
            get
            {
                return !string.IsNullOrWhiteSpace(RecordLockedBy);
            }
        }
        public string RecordLockedBy { get; set; }


    }
}
