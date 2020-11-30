using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class DropDownEntity
    {
        public int ID { get; set; }
        public string Name { get; set; }
    }

    public class DropDownEntityForYears
    {
        public double? Value { get; set; }
        public double? Text { get; set; }
    }
    public class DropDownEntityForString
    {
        public string Value { get; set; }
        public string Text { get; set; }
    }
}
