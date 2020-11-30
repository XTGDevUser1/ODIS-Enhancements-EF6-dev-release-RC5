using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TK.CustomMap.Models
{
    public class GPlacesLocation
    {
        public double Lat { get; set; }
        public double Lng { get; set; }
    }

    public class GPlacesNortheast
    {
        public double Lat { get; set; }
        public double Lng { get; set; }
    }

    public class GPlacesSouthwest
    {
        public double Lat { get; set; }
        public double Lng { get; set; }
    }

    public class GPlacesViewport
    {
        public GPlacesNortheast Northeast { get; set; }
        public GPlacesSouthwest Southwest { get; set; }
    }

    public class GPlacesGeometry
    {
        public GPlacesLocation Location { get; set; }
        public GPlacesViewport Viewport { get; set; }
    }

    public class GPlacesResult
    {
        public GPlacesGeometry Geometry { get; set; }
        public string Icon { get; set; }
        public string Id { get; set; }
        public string Name { get; set; }
        public string Place_Id { get; set; }
        public string Reference { get; set; }
        public string Scope { get; set; }
        public List<string> Types { get; set; }
        public string Vicinity { get; set; }
    }

    public class GooglePlaces
    {
        public List<object> Html_attributions { get; set; }
        public List<GPlacesResult> Results { get; set; }
        public string Status { get; set; }
    }
}
