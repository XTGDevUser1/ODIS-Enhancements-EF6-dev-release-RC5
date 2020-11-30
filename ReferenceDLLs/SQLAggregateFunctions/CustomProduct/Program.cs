using Spatial;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Linq;
using System.Text;


namespace CustomProduct
{
    public static class Program
    {
        public static void Main(string[] args){
            var result = Geocoder.GeocodeUDF(new SqlString("IN"),
                new SqlString("Telangana"),
                new SqlString("Hyderabad"),
                new SqlString("500 038"),
                new SqlString("Aditya Trade Center, Ameerpet"));

            Console.WriteLine("{0} , {1}", result.Lat, result.Long);
        }
    }
}
