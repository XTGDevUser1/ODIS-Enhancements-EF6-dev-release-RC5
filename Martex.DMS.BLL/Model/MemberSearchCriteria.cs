using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// MemberSearchCriteria
    /// </summary>
    public class MemberSearchCriteria
    {
        public int MemberID { get; set; }
        public string MembershipID { get; set; }
        public string MemberNumber { get; set; }
        public string LastName { get; set; }
        public string FirstName { get; set; }
        public int? MemberProgramID { get; set; }
        public int ProgramID { get; set; }
        public string Phone { get; set; }
        public string VIN { get; set; }
        public string State { get; set; }
        public string ZipCode { get; set; }
        public bool MemberFoundFromMobile { get; set; }
        public string CommaSepratedMemberIDList { get; set; }
        public bool EmployeeInd { get; set; }
    }

    /// <summary>
    /// MemberSearchDetails
    /// </summary>
    public class MemberSearchDetails
    {
        public List<Vehicle> Vehicle { get; set; }
        public List<RecentServiceRequest> ServiceRequest { get; set; }
        public List<Member_Information_Result> MemberInformation { get; set; }
        public List<ProgramServiceEventLimit> ProgramServiceEventLimit { get; set; }
        public List<MemberProductsUsingCategory_Result> MemberProducts { get; set; }
    }
}
