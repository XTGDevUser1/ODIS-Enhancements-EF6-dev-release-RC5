using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;


namespace Martex.DMS.DAL
{
    public partial class ISPs_Result //: IComparable
    {
        
        public decimal? CalculatedServiceCost
        {
            get
            {
                /*
            Calculated Service Cost =
            {Base Rate} 
            + ( {Hourly Rate} *{Enroute Drive Time} ) 
            + ( {Hourly Rate} *{Service Drive Time} ) 
            + ( {Enroute Rate} * {Enroute Miles} )
            - ( {Enroute Rate} * ( IF  {Enroute Free Miles}  >  {Enroute Miles}  THEN  {Enroute Miles}   ELSE  {Enroute Free Miles} ) )
            + ( {Service Rate} * { Service Miles} )
            - ( { Service Rate} * ( IF  { Service Free Miles}  >  { Service Miles}  THEN  { Service Miles}   ELSE  { Service Free Miles} ) )
            */
                double? enrouteMiles = (this.EnrouteFreeMiles > this.EnrouteMiles) ? this.EnrouteMiles : this.EnrouteFreeMiles;
                decimal? serviceMiles = (this.ServiceFreeMiles > this.ServiceMiles) ? this.ServiceMiles : this.ServiceFreeMiles;

                decimal? val = this.BaseRate
                                                + (this.HourlyRate * this.EnrouteTimeMinutes)
                                                + (this.HourlyRate * this.ServiceTimeMinutes)
                                                + (this.EnrouteRate * Convert.ToDecimal(this.EnrouteMiles ?? 0))
                                                - (this.EnrouteRate * Convert.ToDecimal(enrouteMiles ?? 0))
                                                + (this.ServiceRate * this.ServiceMiles)
                                                - (this.ServiceRate * (serviceMiles ?? 0));
                return val;
            }
            
        }


        /// <summary>
        /// Compares to.
        /// Sort descending by VendorRank
        /// </summary>
        /// <param name="o">The o.</param>
        /// <returns></returns>
        public int CompareTo(object o)
        {
            ISPs_Result that = o as ISPs_Result;
            return (that.VendorRank - this.VendorRank);
        }

        public decimal? AdminWeight
        {
            get;
            set;
        }
        public decimal? PerfWeight { get; set; }
        public decimal? CostWeight { get; set; }

        public int VendorRank
        {
            get
            {
                /*
( {Vendor’s Administrative Rating} * {Administrative Weighting Percentage} )
+ ( {Vendor’s Service Rating} * {Service Performance Weighting Percentage} ) 
- ( {Calculated Service Cost} * {Cost Weighting Percentage} )
                 */
                decimal? rank = (this.AdministrativeRating * this.AdminWeight)
                                + (this.ProductRating * this.PerfWeight)
                                - (this.CalculatedServiceCost * this.CostWeight);
                
                return Convert.ToInt32(rank??0);
            }
        }

        public decimal EnrouteMilesRounded
        {
            get 
            {
                this.EnrouteMiles = this.EnrouteMiles ?? 0;
                if (this.EnrouteMiles > 0 && this.EnrouteMiles < 1)
                {
                    return 1;
                }
                return (decimal)Math.Round(this.EnrouteMiles.Value);
            }
        }
        public decimal ReturnMilesRounded
        {
            get
            {
                this.ReturnMiles = this.ReturnMiles ?? 0;
                if (this.ReturnMiles > 0 && this.ReturnMiles < 1)
                {
                    return 1;
                }
                return (decimal)Math.Round(this.ReturnMiles.Value);
            }
        }
        public decimal ServiceMilesRounded
        {
            get
            {
                this.ServiceMiles = this.ServiceMiles ?? 0;
                if (this.ServiceMiles > 0 && this.ServiceMiles < 1)
                {
                    return 1;
                }
                return (decimal)Math.Round(this.ServiceMiles.Value);
            }
        }


        /// <summary>
        /// Gets or sets the selection order / index of this item in the ISP selection listing.
        /// </summary>
        /// <value>
        /// The selection order.
        /// </value>
        public int? SelectionOrder { get; set; }

    }
}
