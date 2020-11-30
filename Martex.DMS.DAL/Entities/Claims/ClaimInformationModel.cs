using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;

namespace Martex.DMS.DAL.Entities.Claims
{
    public class ClaimInformationModel
    {
        public Claim Claim { get; set; }
        // Used for Display Purpose
        public string SourceSystemName { get; set; }
        public string PaymentTypeName { get; set; }
        public bool IsFordACES { get; set; }
        public bool IsClaimStatusUpdateAllowed { get; set; }
        public string ClaimStatusName { get; set; }
       
        //Helpers
        public string ClaimTypeName { get; set; }
       
        // For Vendor
        public string VendorName { get; set; }
        public string VendorNumber { get; set; }
       
        // For Membership
        public string MemberName { get; set; }
        public string MembershipNumber { get; set; }
        
        // For Purchase Order
        public string PurchaseOrderNumber { get; set; }

        public decimal MaximumClaimAmountThreshold { get; set; }

        public string ProgramName { get; set; }

        public List<Comment> PreviousComments { get; set; }
        public List<ServiceDiagnosticCodeModel> DiagnosticCodes { get; set; }

        public int? OwnerProgram { get; set; }

        public string ACESClaimStatusName { get; set; }

    }
}
