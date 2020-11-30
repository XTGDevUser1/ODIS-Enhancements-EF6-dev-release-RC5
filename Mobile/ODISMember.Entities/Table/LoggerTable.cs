using SQLite.Net.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Table
{
    public class LoggerTable
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string Trace { get; set; }
        public DateTime CreatedDate { get; set; }
    }
}
