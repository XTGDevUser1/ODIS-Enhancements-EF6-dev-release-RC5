using SQLite.Net.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Table
{
    public class MemberAssociate
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string MemberAssociateInfo { get; set; }
    }
}
