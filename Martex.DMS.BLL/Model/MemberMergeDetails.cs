using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Model
{
    public class MemberMergeDetails
    {
        public string MemberId { get; set; }
        public MemberManagementMemberDetails_Result MemberDetailsResult { get; set; }
        public List<MemberManagementTransactions_Result> Transactions { get; set; }
        public List<PhoneEntityExtended> PhonesList { get; set; }
    }
}
