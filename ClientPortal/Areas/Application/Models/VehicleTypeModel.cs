using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ClientPortal.Areas.Application.Models
{
    public enum VehicleTypes
    {
        Auto=1,
        RV,
        Motorcycle,
        Trailer
    }

    public class VehicleTypeModel
    {

        public bool IsAuto
        {
            get;
            set;
        }

        public bool IsRV
        {
            get;
            set;
        }

        public bool Motorcycle
        {
            get;
            set;
        }

        public bool Trailer
        {
            get;
            set;
        }

        public int RecordCount
        {
            get;
            set;
        }
    }
}