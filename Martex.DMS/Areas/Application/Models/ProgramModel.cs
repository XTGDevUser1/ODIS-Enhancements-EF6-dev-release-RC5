using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.Application.Models
{
    public class ProgramModel
    {
        public string memberPhoneNumber { get; set; }

        public string inBoundNumber { get; set; }

        public bool isFromConnect { get; set; }

        public List<Program> programs { get; set; }
    }
}