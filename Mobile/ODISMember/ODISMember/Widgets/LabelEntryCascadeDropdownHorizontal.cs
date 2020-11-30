using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.CustomControls;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Widgets
{
   public class LabelEntryCascadeDropdownHorizontal : StackLayout
    {
        public ExtendedEntry EntryValuePrimaryDropdown
        {
            get;
            set;
        }
        public ExtendedEntry EntryValueSecondaryDropdown
        {
            get;
            set;
        }
        public ExtendedLabel LabelTitle
        {
            get;
            set;
        }
        public ExtendedLabel LabelError
        {
            get;
            set;
        }        
        public EventHandler Validate
        {
            get;
            set;
        }
        public string KeyPrimary
        {
            get { return SelectedItemPrimary != null ? SelectedItemPrimary.Value.Key : string.Empty; }
        }
        public string ValuePrimary
        {
            get { return SelectedItemPrimary != null ? SelectedItemPrimary.Value.Value : string.Empty; }
        }
        public string KeySecondary
        {
            get { return SelectedItemSecondary != null ? SelectedItemSecondary.Value.Key : string.Empty; }
        }
        public string ValueSecondary
        {
            get { return SelectedItemSecondary != null ? SelectedItemSecondary.Value.Value : string.Empty; }
        }

        public event EventHandler<TextChangedEventArgs> OnPrimaryDropDownSelection;
        public event EventHandler<TextChangedEventArgs> OnSecondaryDropDownSelection;
        public LabelEntryCascadeDropdownHorizontal()
        {
            this.Spacing = 0;
            Padding = new Thickness(10, 5, 10, 5);
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Start
            };
            EntryValuePrimaryDropdown = new ExtendedEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.Start,
                HorizontalTextAlignment = TextAlignment.Start,
                TextColor = ColorResources.EntryLabelValueColor
            };
            EntryValuePrimaryDropdown.TextChanged += EntryValuePrimaryDropdown_TextChanged;


            EntryValueSecondaryDropdown = new ExtendedEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                HorizontalTextAlignment = TextAlignment.Start,
                TextColor = ColorResources.EntryLabelValueColor
            };
            EntryValueSecondaryDropdown.TextChanged += EntryValueSecondaryDropdown_TextChanged;


            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor
            };

            EntryValuePrimaryDropdown.Focused += EntryValuePrimaryDropdown_Focused;
            EntryValuePrimaryDropdown.LeftSwipe = (object s, EventArgs e) => {

            };
            EntryValuePrimaryDropdown.RightSwipe = (object s, EventArgs e) => {

            };

            EntryValueSecondaryDropdown.Focused += EntryValueSecondaryDropdown_Focused;
            EntryValueSecondaryDropdown.LeftSwipe = (object s, EventArgs e) => {

            };
            EntryValueSecondaryDropdown.RightSwipe = (object s, EventArgs e) => {

            };

            Grid grid = new Grid
            {
               HorizontalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions =
                {
                    new RowDefinition { Height = GridLength.Auto },
                    new RowDefinition { Height = GridLength.Auto }
                },
                ColumnDefinitions =
                {
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                }
            };

            Grid innerGrid = new Grid
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions =
                {
                    new RowDefinition { Height = GridLength.Auto }
                },
                ColumnDefinitions =
                {
                    new ColumnDefinition { Width = new GridLength(50) },
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                }
            };
            //StackLayout dropdownLayout = new StackLayout() {
            //    Orientation = StackOrientation.Horizontal,
            //    HorizontalOptions = LayoutOptions.FillAndExpand,
            //    Spacing = 2
            //};
            innerGrid.Children.Add(EntryValuePrimaryDropdown, 0, 0);
            innerGrid.Children.Add(EntryValueSecondaryDropdown,1, 0);

            grid.Children.Add(LabelTitle, 0, 0);
            grid.Children.Add(innerGrid, 1, 0);
            //grid.Children.Add(EntryValuePrimaryDropdown, 1, 0);
            // grid.Children.Add(EntryValueSecondaryDropdown, 2, 0);
            //grid.Children.Add(LabelError, 1, 2);
            grid.Children.Add(LabelError, 1, 1);
            this.Children.Add(grid);
        }
        private void EntryValuePrimaryDropdown_Focused(object sender, FocusEventArgs e)
        {
            if (e.IsFocused)
            {
                CustomDropDownList dropDownPrimary = new CustomDropDownList();
                dropDownPrimary.ItemSource = this.ItemSourcePrimary;
                dropDownPrimary.OnItemSelect -= DropDownPrimary_OnItemSelect;
                dropDownPrimary.OnItemSelect += DropDownPrimary_OnItemSelect;
                this.Navigation.PushAsync(dropDownPrimary);
            }
        }
        private void EntryValueSecondaryDropdown_Focused(object sender, FocusEventArgs e)
        {
            if (e.IsFocused)
            {
                CustomDropDownList dropDownSecondary = new CustomDropDownList();
                dropDownSecondary.ItemSource = this.ItemSourceSecondary;
                dropDownSecondary.OnItemSelect -= DropDownSecondary_OnItemSelect;
                dropDownSecondary.OnItemSelect += DropDownSecondary_OnItemSelect;
                this.Navigation.PushAsync(dropDownSecondary);
            }
        }
        private void DropDownPrimary_OnItemSelect(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                SelectedItemPrimary = (KeyValuePair<string, string>)e.SelectedItem;
                if (SelectedItemPrimary.Value.Key == "Select")
                {
                    EntryValuePrimaryDropdown.Text = string.Empty;
                    SelectedItemPrimary = null;
                }
                else
                {
                    EntryValuePrimaryDropdown.Text = SelectedItemPrimary.Value.Key;
                }
                EntryValuePrimaryDropdown.Unfocus();
            }
        }
        private void DropDownSecondary_OnItemSelect(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                SelectedItemSecondary = (KeyValuePair<string, string>)e.SelectedItem;
                if (SelectedItemSecondary.Value.Key == "Select")
                {
                    EntryValueSecondaryDropdown.Text = string.Empty;
                    SelectedItemSecondary = null;
                }
                else
                {
                    EntryValueSecondaryDropdown.Text = SelectedItemSecondary.Value.Key;
                }
                EntryValueSecondaryDropdown.Unfocus();
            }
        }
        private void EntryValuePrimaryDropdown_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrEmpty(e.NewTextValue))
            {
                SelectedItemPrimary = null;
            }
            if (OnPrimaryDropDownSelection != null)
            {
                OnPrimaryDropDownSelection.Invoke(sender, e);
            }
        }
        private void EntryValueSecondaryDropdown_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrEmpty(e.NewTextValue))
            {
                SelectedItemSecondary = null;
            }
            if (OnSecondaryDropDownSelection != null)
            {
                OnSecondaryDropDownSelection.Invoke(sender, e);
            }
        }


        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.LabelText = newValue;
                });

        public string LabelText
        {
            get { return (string)GetValue(LabelTextProperty); }
            set
            {
                SetValue(LabelTextProperty, value);
                LabelTitle.Text = value;
            }
        }

        public static BindableProperty EntryHintPrimaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.EntryHintPrimary,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.EntryHintPrimary = newValue;
                });

        public string EntryHintPrimary
        {
            get { return (string)GetValue(EntryHintPrimaryProperty); }
            set
            {
                SetValue(EntryHintPrimaryProperty, value);
                EntryValuePrimaryDropdown.Placeholder = value;
            }
        }

        public static BindableProperty EntryHintSecondaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.EntryHintSecondary,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.EntryHintSecondary = newValue;
                });

        public string EntryHintSecondary
        {
            get { return (string)GetValue(EntryHintSecondaryProperty); }
            set
            {
                SetValue(EntryHintSecondaryProperty, value);
                EntryValueSecondaryDropdown.Placeholder = value;
            }
        }

        public static BindableProperty EntryTextPrimaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.EntryTextPrimary,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.EntryTextPrimary = newValue;
                });

        public string EntryTextPrimary
        {
            get { return (string)EntryValuePrimaryDropdown.Text; }//GetValue(EntryTextProperty);
            set
            {
                SetValue(EntryTextPrimaryProperty, value);
                EntryValuePrimaryDropdown.Text = value;
            }
        }
        public static BindableProperty EntryTextSecondaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.EntryTextSecondary,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.EntryTextSecondary = newValue;
                });

        public string EntryTextSecondary
        {
            get { return (string)EntryValueSecondaryDropdown.Text; }//GetValue(EntryTextProperty);
            set
            {
                SetValue(EntryTextSecondaryProperty, value);
                EntryValueSecondaryDropdown.Text = value;
            }
        }


        public static BindableProperty IsValidProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.IsValid = newValue;
                });

        public bool IsValid
        {
            get { return (bool)GetValue(IsValidProperty); }
            set
            {
                SetValue(IsValidProperty, value);
            }
        }

        public static BindableProperty EntryErrorMessageProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.EntryErrorMessage = newValue;
                });

        public string EntryErrorMessage
        {
            get { return (string)GetValue(EntryErrorMessageProperty); }
            set
            {
                SetValue(EntryErrorMessageProperty, value);
                LabelError.Text = value;
            }
        }

        public static BindableProperty IsLabelVisibleProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.IsLabelVisible = newValue;
                });

        public bool IsLabelVisible
        {
            get { return (bool)GetValue(IsLabelVisibleProperty); }
            set
            {
                SetValue(IsLabelVisibleProperty, value);
                if (value == false)
                {
                    LabelTitle.HeightRequest = 0;
                }
            }
        }
        public static BindableProperty ItemSourcePrimaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, Dictionary<string, string>>(ctrl => ctrl.ItemSourcePrimary,
                defaultValue: new Dictionary<string, string>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.ItemSourcePrimary = newValue;
                });

        public Dictionary<string, string> ItemSourcePrimary
        {
            get { return (Dictionary<string, string>)GetValue(ItemSourcePrimaryProperty); }
            set
            {
                SetValue(ItemSourcePrimaryProperty, value);
            }
        }
        public static BindableProperty ItemSourceSecondaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, Dictionary<string, string>>(ctrl => ctrl.ItemSourceSecondary,
                defaultValue: new Dictionary<string, string>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.ItemSourceSecondary = newValue;
                });

        public Dictionary<string, string> ItemSourceSecondary
        {
            get { return (Dictionary<string, string>)GetValue(ItemSourceSecondaryProperty); }
            set
            {
                SetValue(ItemSourceSecondaryProperty, value);
            }
        }

        public static BindableProperty SelectedItemPrimaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, KeyValuePair<string, string>?>(ctrl => ctrl.SelectedItemPrimary,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.SelectedItemPrimary = newValue;
                });

        public KeyValuePair<string, string>? SelectedItemPrimary
        {
            get { return (KeyValuePair<string, string>?)GetValue(SelectedItemPrimaryProperty); }
            set
            {
                SetValue(SelectedItemPrimaryProperty, value);

            }
        }

        public static BindableProperty SelectedItemSecondaryProperty =
            BindableProperty.Create<LabelEntryCascadeDropdownHorizontal, KeyValuePair<string, string>?>(ctrl => ctrl.SelectedItemSecondary,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryCascadeDropdownHorizontal)bindable;
                    ctrl.SelectedItemSecondary = newValue;
                });

        public KeyValuePair<string, string>? SelectedItemSecondary
        {
            get { return (KeyValuePair<string, string>?)GetValue(SelectedItemSecondaryProperty); }
            set
            {
                SetValue(SelectedItemSecondaryProperty, value);

            }
        }
        
    }
}
