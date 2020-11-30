using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class CustomDropDownList : ContentPage
    {
        public ListView DropDown;
        public SearchBar Search;
        public StackLayout stackMain;
        public ExtendedLabel noRecordLabel;
        public event EventHandler<SelectedItemChangedEventArgs> OnItemSelect;
        public Func<Dictionary<string, string>, Dictionary<string, string>> LoadItemSource;
        public Dictionary<string, string> LoadItemSourceParam;
        public CustomDropDownList()
        {

            Search = new SearchBar()
            {
                Placeholder = "Search"
            };

            Search.TextChanged += Search_TextChanged;
            Search.SearchButtonPressed += Search_SearchButtonPressed;
            DropDown = new ListView()
            {
                HasUnevenRows = true,
                SeparatorColor = Color.Silver,
                ItemTemplate = new DataTemplate(() =>
                {
                    ExtendedLabel nameLabel = new ExtendedLabel()
                    {
                        Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                        HorizontalTextAlignment = TextAlignment.Start

                    };
                    nameLabel.SetBinding(ExtendedLabel.TextProperty, "Key");
                    return new ViewCell
                    {
                        View = new StackLayout
                        {
                            Children =
                                {
                                    new StackLayout
                                    {
                                        Spacing = 0,
                                        Padding = new Thickness(20,5,5,5),
                                        Children =
                                        {
                                            nameLabel
                                        }
                                    }
                                }
                        }
                    };
                })
            };
            DropDown.ItemSelected += DropDown_ItemSelected;
            noRecordLabel = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Center,
                Text = "Loading...",
                IsVisible = true,
            };
            Search.Unfocus();
            stackMain = new StackLayout();
            stackMain.Children.Add(Search);
            stackMain.Children.Add(noRecordLabel);
            stackMain.Children.Add(DropDown);
            this.Content = stackMain;
        }

        protected override void OnAppearing()
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                HUD hud = new HUD("Loading...");

                if (this.ItemSource == null || this.ItemSource.Count == 0)
                {
                    if (this.LoadItemSource != null)
                    {
                        this.ItemSource = LoadItemSource.Invoke(LoadItemSourceParam);
                    }
                }

                if (this.ItemSource.Count == 0)
                {
                    noRecordLabel.IsVisible = true;
                    noRecordLabel.Text = "No records found";
                    DropDown.IsVisible = false;
                }
                else
                {
                    noRecordLabel.IsVisible = false;
                    DropDown.IsVisible = true;

                    Dictionary<string, string> dropDownValues = new Dictionary<string, string>();
                    dropDownValues.Add("Select", "Select");
                    Dictionary<string, string> newDropdownValues = dropDownValues.Concat(this.ItemSource).ToDictionary(x => x.Key, x => x.Value);


                    DropDown.ItemsSource = newDropdownValues;
                }
                hud.Dismiss();
            });
        }

        public void onSearch()
        {
            if (string.IsNullOrEmpty(Search.Text))
            {
                if (ItemSource.Count == 0)
                {
                    noRecordLabel.IsVisible = true;
                    noRecordLabel.Text = "No records found";
                    DropDown.IsVisible = false;
                }
                else
                {
                    noRecordLabel.IsVisible = false;
                    DropDown.IsVisible = true;
                }

                Dictionary<string, string> dropDownValues = new Dictionary<string, string>();
                dropDownValues.Add("Select", "Select");
                Dictionary<string, string> newDropdownValues = dropDownValues.Concat(ItemSource).ToDictionary(x => x.Key, x => x.Value);

                DropDown.ItemsSource = newDropdownValues;
            }
            else
            {

                Dictionary<string, string> result = ItemSource.Where(a => a.Key.ToLower().Contains(Search.Text.ToLower())).ToDictionary(p => p.Key, p => p.Value);

                if (result.Count == 0)
                {
                    noRecordLabel.IsVisible = true;
                    noRecordLabel.Text = "No records found";
                    DropDown.IsVisible = false;
                }
                else
                {
                    noRecordLabel.IsVisible = false;
                    DropDown.IsVisible = true;
                    Dictionary<string, string> dropDownValues = new Dictionary<string, string>();
                    dropDownValues.Add("Select", "Select");
                    Dictionary<string, string> newDropdownValues = dropDownValues.Concat(result).ToDictionary(x => x.Key, x => x.Value);

                    DropDown.ItemsSource = newDropdownValues;
                }
            }
        }


        private void Search_TextChanged(object sender, TextChangedEventArgs e)
        {
            onSearch();
        }
        private void Search_SearchButtonPressed(object sender, EventArgs e)
        {
            onSearch();
        }
        private void DropDown_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (OnItemSelect != null)
            {
                OnItemSelect(sender, e);
            }
            this.Navigation.PopAsync();
        }

        public static BindableProperty ItemSourceProperty =
            BindableProperty.Create<CustomDropDownList, Dictionary<string, string>>(ctrl => ctrl.ItemSource,
                defaultValue: new Dictionary<string, string>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (CustomDropDownList)bindable;
                    ctrl.ItemSource = newValue;
                });

        public Dictionary<string, string> ItemSource
        {
            get { return (Dictionary<string, string>)GetValue(ItemSourceProperty); }
            set
            {
                SetValue(ItemSourceProperty, value);

            }
        }
    }
}
