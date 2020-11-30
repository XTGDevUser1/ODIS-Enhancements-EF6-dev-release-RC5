using ODISMember.Classes;
using ODISMember.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using TK.CustomMap.Api;
using TK.CustomMap.Api.Bing;
using TK.CustomMap.Api.Google;
using TK.CustomMap.Api.OSM;
using Xamarin.Forms;
using Xamarin.Forms.Maps;

namespace ODISMember.CustomControls
{
    public class PlacesAutoComplete : RelativeLayout
    {
        public static readonly BindableProperty BoundsProperty =
            BindableProperty.Create<PlacesAutoComplete, MapSpan>(p => p.Bounds, default(MapSpan));

        public static readonly BindableProperty PlaceSelectedCommandProperty =
            BindableProperty.Create<PlacesAutoComplete, Command<IPlaceResult>>(
                p => p.PlaceSelectedCommand,
                null);

        public static BindableProperty IsUserCurrentLocationButtonVisibleProperty =
           BindableProperty.Create<PlacesAutoComplete, bool>(p => p.IsUserCurrentLocationButtonVisible,
               defaultValue: false,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) =>
               {
                   var ctrl = (PlacesAutoComplete)bindable;
                   ctrl.IsUserCurrentLocationButtonVisible = newValue;
               });

        public static BindableProperty SearchPositionProperty =
            BindableProperty.Create<PlacesAutoComplete, TK.CustomMap.TKCustomMapPin>(p => p.SearchPosition,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (PlacesAutoComplete)bindable;
                    ctrl.SearchPosition = newValue;
                });

        public TK.CustomMap.TKCustomMap MapView;
        private readonly bool _useSearchBar;
        private readonly int _mapBottomSpacing;
        private ListView _autoCompleteListView;
        private Entry _entry;
        private IEnumerable<IPlaceResult> _predictions;
        private SearchBar _searchBar;
        private bool _textChangeItemSelected;
        private bool isSearchTextPlotted = false;
        private View searchView;
        private CustomImageButton UserLocation;

        public PlacesAutoComplete(bool useSearchBar,int mapBottomSpace)
        {
            this._useSearchBar = useSearchBar;
            this._mapBottomSpacing = mapBottomSpace;
            this.Init();
        }

        public PlacesAutoComplete()
        {
            this.Padding = new Thickness(0);
            this._useSearchBar = true;
            this.Init();
        }

        public event EventHandler CurrentLocationClicked;

        // TODO: SUMMARIES
        public enum PlacesApi
        {
            Google,
            Osm,
            Native,
            Bing,
            BingBusiness
        }

        public PlacesApi ApiToUse { get; set; }

        public MapSpan Bounds
        {
            get { return (MapSpan)this.GetValue(BoundsProperty); }
            set { this.SetValue(BoundsProperty, value); }
        }

        public double HeightOfSearchBar
        {
            get
            {
                return this._useSearchBar ? this._searchBar.Height : this._entry.Height;
            }
        }

        //public static readonly BindableProperty SearchPositionProperty =
        //   BindableProperty.Create<PlacesAutoComplete, TK.CustomMap.TKCustomMapPin>(p => p.SearchPosition, null);
        public bool IsUserCurrentLocationButtonVisible
        {
            get
            {
                return (bool)this.GetValue(IsUserCurrentLocationButtonVisibleProperty);
            }
            set
            {
                this.SetValue(IsUserCurrentLocationButtonVisibleProperty, value);
                if (UserLocation != null)
                {
                    UserLocation.IsVisible = value;
                }
            }
        }

        public string Placeholder
        {
            get { return this._useSearchBar ? this._searchBar.Placeholder : this._entry.Placeholder; }
            set
            {
                if (this._useSearchBar)
                    this._searchBar.Placeholder = value;
                else
                    this._entry.Placeholder = value;
            }
        }

        public Command<IPlaceResult> PlaceSelectedCommand
        {
            get { return (Command<IPlaceResult>)this.GetValue(PlaceSelectedCommandProperty); }
            set { this.SetValue(PlaceSelectedCommandProperty, value); }
        }

        public TK.CustomMap.TKCustomMapPin SearchPosition
        {
            get
            {
                return (TK.CustomMap.TKCustomMapPin)this.GetValue(SearchPositionProperty);
            }
            set
            {
                this.SetValue(SearchPositionProperty, value);
                if (value != null)
                {
                    this._searchBar.TextChanged -= SearchTextChanged;
                    _searchBar.Text = value.Title;
                    this._searchBar.TextChanged += SearchTextChanged;
                }
            }
        }

        #region ODIS MEMBER Mobile Custom Written

        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }

        #endregion ODIS MEMBER Mobile Custom Written

        private string SearchText
        {
            get
            {
                return this._useSearchBar ? this._searchBar.Text : this._entry.Text;
            }
            set
            {
                if (this._useSearchBar)
                    this._searchBar.Text = value;
                else
                    this._entry.Text = value;
            }
        }

        private void AddorRemoveAutoCompleteListView(bool isAdd)
        {
        }

        private void HandleItemSelected(IPlaceResult prediction)
        {
            if (this.PlaceSelectedCommand != null && this.PlaceSelectedCommand.CanExecute(this))
            {
                this.PlaceSelectedCommand.Execute(prediction);
            }

            this._textChangeItemSelected = true;

            this.SearchText = prediction.Description;
            this._autoCompleteListView.SelectedItem = null;

            this.Reset();
        }

        private void Init()
        {
            OsmNominatim.Instance.CountryCodes.Add("de");

            this._autoCompleteListView = new ListView
            {
                IsVisible = false,
                //RowHeight = 40,
                HasUnevenRows = true,
                // HeightRequest = 0,
                BackgroundColor = Color.White
            };
            this._autoCompleteListView.ItemTemplate = new DataTemplate(() =>
            {
                var cell = new TextCell();
                cell.SetBinding(ImageCell.TextProperty, "Description");

                return cell;
            });

            if (this._useSearchBar)
            {
                this._searchBar = new SearchBar
                {
                    Placeholder = "Search for address...",
                    BackgroundColor = Color.White
                };
                this._searchBar.TextChanged += SearchTextChanged;
                this._searchBar.SearchButtonPressed += SearchButtonPressed;

                searchView = this._searchBar;
            }
            else
            {
                this._entry = new Entry
                {
                    Placeholder = "Search for address",
                    BackgroundColor = Color.White
                };
                this._entry.TextChanged += SearchTextChanged;

                searchView = this._entry;
            }
            UserLocation = new CustomImageButton()
            {
                ImageUrl = ImagePathResources.UserCurrentLocationIcon,
                HeightRequest = 50,
                WidthRequest = 50,
                IsVisible = false
            };
            UserLocation.CustomImage.Opacity = 0.5;
            UserLocation.ImageClick += UserLocation_ImageClick;

            var mapspan = MapSpan.FromCenterAndRadius(new Position(Constants.DEFAULT_LATITUDE, Constants.DEFAULT_LONGITUDE), Distance.FromMiles(500));

            MapView = new TK.CustomMap.TKCustomMap(mapspan);
            MapView.VerticalOptions = LayoutOptions.FillAndExpand;
            this.Children.Add(searchView,
                Constraint.Constant(0),
                Constraint.Constant(0),
                widthConstraint: Constraint.RelativeToParent(l => { return l.Width; }));

            this.Children.Add(
                  MapView,
                  Constraint.Constant(0),
                   Constraint.RelativeToView(searchView, (r, v) => { return v.Y + v.Height; }),
            widthConstraint: Constraint.RelativeToParent(r => { return r.Width; }),
             heightConstraint: Constraint.RelativeToParent(r => { return r.Height - this._mapBottomSpacing; }));

            this.Children.Add(UserLocation,
              Constraint.RelativeToView(searchView, (r, v) => { return v.Width - 60; }),
              Constraint.RelativeToView(searchView, (r, v) => { return v.Y + v.Height + 10; }),
           widthConstraint: Constraint.Constant(50),
           heightConstraint: Constraint.Constant(50));

            this.Children.Add(
                    this._autoCompleteListView,
                    Constraint.Constant(0),
                    Constraint.RelativeToView(searchView, (r, v) => { return v.Y + v.Height; }));

            this._autoCompleteListView.ItemSelected += ItemSelected;

            this._textChangeItemSelected = false;
        }

        private void ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null) return;
            var prediction = (IPlaceResult)e.SelectedItem;

            this.HandleItemSelected(prediction);
        }

        private void Reset()
        {
            this._autoCompleteListView.ItemsSource = null;
            this._autoCompleteListView.IsVisible = false;
            AddorRemoveAutoCompleteListView(false);
            // this._autoCompleteListView.HeightRequest = 0;

            if (this._useSearchBar)
                this._searchBar.Unfocus();
            else
                this._entry.Unfocus();
        }

        private void SearchButtonPressed(object sender, EventArgs e)
        {
            if (this._predictions != null && this._predictions.Any())
                this.HandleItemSelected(this._predictions.First());
            else
                this.Reset();
        }

        private async void SearchPlaces()
        {
            try
            {
                if (string.IsNullOrEmpty(this.SearchText))
                {
                    this._autoCompleteListView.ItemsSource = null;
                    this._autoCompleteListView.IsVisible = false;
                    AddorRemoveAutoCompleteListView(false);
                    //this._autoCompleteListView.HeightRequest = 0;
                    return;
                }

                IEnumerable<IPlaceResult> result = null;

                if (this.ApiToUse == PlacesApi.Google)
                {
                    var apiResult = await GmsPlace.Instance.GetPredictions(this.SearchText);

                    if (apiResult != null)
                    {
                        result = apiResult.Predictions;
                    }
                }
                else if (this.ApiToUse == PlacesApi.Native)
                {
                    result = await TKNativePlacesApi.Instance.GetPredictions(this.SearchText, this.Bounds);
                }
                else if (this.ApiToUse == PlacesApi.Bing)
                {
                    result = await BingLocations.Instance.GetPredictions(this.SearchText);
                }
                else if (this.ApiToUse == PlacesApi.BingBusiness)
                {
                    //TFS: 1397 if search text start with digit we consider it as address else it will be business
                    if (!(SearchText.Trim().Length > 0 && char.IsDigit(SearchText.Trim()[0])))
                    {
                        if (SearchPosition != null && SearchPosition.Position != null)
                        {
                            result = await BingLocations.Instance.GetBusinessSearchResults(this.SearchText, (decimal)SearchPosition.Position.Latitude, (decimal)SearchPosition.Position.Longitude);
                        }
                        else
                        {
                            result = await BingLocations.Instance.GetBusinessSearchResults(this.SearchText, this.Latitude, this.Longitude);
                        }
                    }
                    else
                    {
                        result = await BingLocations.Instance.GetPredictions(this.SearchText);
                    }
                }
                else
                {
                    result = await OsmNominatim.Instance.GetPredictions(this.SearchText);
                }

                UpdateResults(result);
            }
            catch
            {
                // TODO
            }
        }

        private void SearchTextChanged(object sender, TextChangedEventArgs e)
        {
            if (this._textChangeItemSelected)
            {
                this._textChangeItemSelected = false;
                return;
            }

            this.SearchPlaces();
        }

        private void UpdateResults(IEnumerable<IPlaceResult> result)
        {
            if (result != null && result.Any())
            {
                this._predictions = result;

                // this._autoCompleteListView.HeightRequest = result.Count() * 40;
                this._autoCompleteListView.IsVisible = true;
                AddorRemoveAutoCompleteListView(true);
                this._autoCompleteListView.ItemsSource = this._predictions;
            }
            else
            {
                //this._autoCompleteListView.HeightRequest = 0;
                this._autoCompleteListView.IsVisible = false;
                AddorRemoveAutoCompleteListView(false);
            }
        }

        private void UserLocation_ImageClick(object sender, EventArgs e)
        {
            this.CurrentLocationClicked?.Invoke(sender, e);
        }
    }
}