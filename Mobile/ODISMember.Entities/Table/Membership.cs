using SQLite.Net.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Table
{
    public class Membership
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string MembershipInfo { get; set; }
    }
}
