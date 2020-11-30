using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class VehicleModel : IEqualityComparer<VehicleModel>
    {
        public int ID { get; set; }
        public string Model { get; set; }

        public bool Equals(VehicleModel x, VehicleModel y)
        {
            return x.Model.Equals(y.Model);
        }

        public int GetHashCode(VehicleModel obj)
        {
            return obj.Model.GetHashCode();
        }

    }

    public class VehicleMake : IEqualityComparer<VehicleMake>
    {

        public int ID { get; set; }
        public string Make { get; set; }
        public bool Equals(VehicleMake x, VehicleMake y)
        {
            return x.Make.Equals(y.Make);
        }

        public int GetHashCode(VehicleMake obj)
        {
            return obj.Make.GetHashCode();
        }
    }

    public class VehicleModelYear : IEqualityComparer<VehicleModelYear>
    {
        public int ID { get; set; }
        protected double? year;
        public double? Year
        {
            get
            {
                if (year.HasValue)
                {
                    return year;
                }
                return (double?)0;
            }
            set
            {
                year = value;
            }
        }

        public bool Equals(VehicleModelYear x, VehicleModelYear y)
        {
            return x.Year.GetValueOrDefault().Equals(y.Year.GetValueOrDefault());
        }

        public int GetHashCode(VehicleModelYear obj)
        {
            return obj.Year.GetValueOrDefault().GetHashCode();
        }
    }
}
