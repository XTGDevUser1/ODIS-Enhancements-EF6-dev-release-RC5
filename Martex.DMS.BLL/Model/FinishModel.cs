using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// FinishModel
    /// </summary>
    public class FinishModel
    {
        public string ConnectData
        {
            get;
            set;
        }
        public string AmazonConnectID
        {
            get;
            set;
        }
        public bool LogWarmTransfer
        {
            get;
            set;
        }

        public int ContactCategory
        {
            get;
            set;
        }

        public FinishReasonsActionsModel ReasonsActions
        {
            get;
            set;
        }
        public List<int> SelectedReasons
        {
            get;
            set;
        }
        public List<int> SelectedActions
        {
            get;
            set;
        }

        public int ServiceRequestStatus
        {
            get;
            set;
        }

        public int? NextAction
        {
            get;
            set;
        }

        public DateTime? ScheduledDate
        {
            get;
            set;
        }

        public int? AssignedTo
        {
            get;
            set;
        }

        public int? Priority
        {
            get;
            set;
        }

        public int ClosedLoopStatus
        {
            get;
            set;
        }

        public DateTime? NextSend
        {
            get;
            set;
        }

        public string Comments
        {
            get;
            set;
        }

        public List<ClosedLoopActivities_Result> ClosedLoopActivities
        {
            get;
            set;
        }

        public int ServiceRequestID { get; set; }
        public int CaseID { get; set; }
        public int ProgramID { get; set; }
        public int MemberID { get; set; }
        public int? ANIPhoneTypeID { get; set; }
        public string ANIPhoneNumber { get; set; }

        public int InBoundCallId
        {
            get;
            set;
        }

        public Dictionary<string, string> DynamicDataElements { get; set; }

        public string ActiveRequestLockedComments { get; set; }
        public bool SendNotification { get; set; }

        public int? MemberPaymentTypeID
        {
            get;
            set;
        }

        public bool? IsSMSAvailable
        {
            get;
            set;
        }

        public string ServiceRequestEmail
        {
            get;
            set;
        }

        public int? DeclinedReason
        {
            get;
            set;
        }

        public string ProductProviderDescription { get; set; }
        public string ProviderClaimNumber { get; set; }

        public int? ProductProviderID { get; set; }

        public bool? IsShowConfirmPrompt { get; set; }
    }
}
