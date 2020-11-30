using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TK.CustomMap.Overlays;
using TK.CustomMap;

namespace ODISMember.CustomControls
{
    /// <summary>
    /// Pin which is either source or destination of a route
    /// </summary>
    public class RoutePin : TKCustomMapPin
    {
        /// <summary>
        /// Gets/Sets if the pin is the source of a route. If <value>false</value> pin is destination
        /// </summary>
        public bool IsSource { get; set; }
        /// <summary>
        /// Gets/Sets reference to the route
        /// </summary>
        public TKRoute Route { get; set; }
    }
}
