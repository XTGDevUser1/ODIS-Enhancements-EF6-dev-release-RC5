using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Model;
using ODISMember.Services.Service;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TK.CustomMap;
using Xamarin.Forms;
using Xamarin.Forms.Maps;

namespace ODISMember.CustomControls
{
    public class CustomMapView : RelativeLayout
    {
        LoggerHelper logger = new LoggerHelper();
        MapViewModel mapViewModel;
        public CustomMapView() {
            mapViewModel = new MapViewModel();
            this.BindingContext = mapViewModel;
            CreateView();
        }
        private void CreateView()
        {
            try
            {
                var autoComplete = new PlacesAutoComplete { ApiToUse = PlacesAutoComplete.PlacesApi.Native };
                autoComplete.SetBinding(PlacesAutoComplete.PlaceSelectedCommandProperty, "PlaceSelectedCommand");

                var mapView = new TKCustomMap();

                mapView.SetBinding(TKCustomMap.CustomPinsProperty, "Pins");
                mapView.SetBinding(TKCustomMap.MapClickedCommandProperty, "MapClickedCommand");
                mapView.SetBinding(TKCustomMap.MapLongPressCommandProperty, "MapLongPressCommand");
                mapView.SetBinding(TKCustomMap.MapCenterProperty, "MapCenter");
                mapView.SetBinding(TKCustomMap.PinSelectedCommandProperty, "PinSelectedCommand");
                mapView.SetBinding(TKCustomMap.SelectedPinProperty, "SelectedPin");
                mapView.SetBinding(TKCustomMap.RoutesProperty, "Routes");
                mapView.SetBinding(TKCustomMap.PinDragEndCommandProperty, "DragEndCommand");
                mapView.SetBinding(TKCustomMap.CirclesProperty, "Circles");
                mapView.SetBinding(TKCustomMap.CalloutClickedCommandProperty, "CalloutClickedCommand");
                mapView.SetBinding(TKCustomMap.PolylinesProperty, "Lines");
                mapView.SetBinding(TKCustomMap.PolygonsProperty, "Polygons");
                mapView.SetBinding(TKCustomMap.MapRegionProperty, "MapRegion");
                mapView.SetBinding(TKCustomMap.RouteClickedCommandProperty, "RouteClickedCommand");
                mapView.SetBinding(TKCustomMap.RouteCalculationFinishedCommandProperty, "RouteCalculationFinishedCommand");
                mapView.SetBinding(TKCustomMap.TilesUrlOptionsProperty, "TilesUrlOptions");
                //mapView.IsRegionChangeAnimated = true;


                autoComplete.SetBinding(PlacesAutoComplete.BoundsProperty, "MapRegion");



                this.Children.Add(
                  mapView,
                  Constraint.Constant(0),
                   Constraint.Constant(50),
                   Constraint.RelativeToParent(r => r.Width),
                   Constraint.RelativeToParent(r => r.Height));
                this.Children.Add(
                   autoComplete,
                   Constraint.Constant(0),
                    Constraint.Constant(0)
                   );

                var position = new Xamarin.Forms.Maps.Position(Constants.DEFAULT_LATITUDE, Constants.DEFAULT_LONGITUDE);//Default to Source Position
                var mapspan = MapSpan.FromCenterAndRadius(position, Distance.FromMiles(500));
                mapView.MoveToRegion(mapspan);
            }
            catch (Exception ex)
            {
                logger.Error(ex);
            }
        }

        public TKCustomMapPin GetSelectedPin() {
            return mapViewModel.SelectedPin;
        }
    }
}
