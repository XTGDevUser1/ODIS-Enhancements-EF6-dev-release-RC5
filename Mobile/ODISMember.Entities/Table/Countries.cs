using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQLite.Net.Attributes;

namespace ODISMember.Entities.Table
{
    public class Countries
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string CountryName { get; set; }
        public string ISOCode { get; set; }
        public string ISOCode3 { get; set; }
        public long SystemIdentifier { get; set; }
        public string TelephoneCode { get; set; }
    }
}
