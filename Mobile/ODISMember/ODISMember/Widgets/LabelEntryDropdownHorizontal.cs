using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using ODISMember.Classes;
using FFImageLoading.Forms;
using ODISMember.CustomControls;

namespace ODISMember.Widgets
{
    public partial class LabelEntryDropdownHorizontal : StackLayout
    {
        public ExtendedEntry EntryValue
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
        public CachedImage ImageValidate
        {
            get;
            set;
        }
        public EventHandler Validate
        {
            get;
            set;
        }
        public string Key {
            get { return SelectedItem != null ? SelectedItem.Value.Key : string.Empty; }
        }
        public string Value
        {
            get { return SelectedItem != null ? SelectedItem.Value.Value : string.Empty; }
        }
        public event EventHandler<TextChangedEventArgs> OnDropDownSelection;
        //public KeyValuePair<string, string>? SelectedItem { get; set; }
        public LabelEntryDropdownHorizontal()
        {
            this.Spacing = 0;
            Padding = new Thickness(10, 5, 10, 5);
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Start
            };
            EntryValue = new ExtendedEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                HorizontalTextAlignment = TextAlignment.Start,
                TextColor = ColorResources.EntryLabelValueColor
            };
            EntryValue.TextChanged += EntryValue_TextChanged;
            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor
            };
            ImageValidate = new CachedImage()
            {
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
                WidthRequest = 20,
                HeightRequest = 20,
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false

            };
            EntryValue.Focused += EntryValue_Focused;
            EntryValue.LeftSwipe = (object s, EventArgs e) => {

            };
            EntryValue.RightSwipe = (object s, EventArgs e) => {

            };
            //StackLayout stack = new StackLayout()
            //{
            //    Orientation = StackOrientation.Horizontal
            //};
            //stack.Children.Add(EntryValue);
            //stack.Children.Add(ImageValidate);

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
                    new ColumnDefinition  { Width = new GridLength(1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                }
            };

            grid.Children.Add(LabelTitle, 0, 0);
            grid.Children.Add(EntryValue, 1, 0);
            grid.Children.Add(LabelError, 1, 1);
            this.Children.Add(grid);
        }
        public bool onValidate()
        {
            Validate.Invoke(new object(), EventArgs.Empty);
            return IsValid;
        }
        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrEmpty(e.NewTextValue)) {
                SelectedItem = null;
            }
            if (OnDropDownSelection != null)
            {
                OnDropDownSelection.Invoke(sender, e);
            }
        }
        private void DropDown_OnItemSelect(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                SelectedItem = (KeyValuePair<string, string>)e.SelectedItem;
                if (SelectedItem.Value.Key == "Select")
                {
                    EntryValue.Text = string.Empty;
                    SelectedItem = null;
                }
                else {
                    EntryValue.Text = SelectedItem.Value.Key;
                }
                EntryValue.Unfocus();
            }
        }
        private void EntryValue_Focused(object sender, FocusEventArgs e)
        {
            if (e.IsFocused)
            {
                CustomDropDownList dropDown = new CustomDropDownList();
                dropDown.ItemSource = this.ItemSource;
                dropDown.OnItemSelect -= DropDown_OnItemSelect;
                dropDown.OnItemSelect += DropDown_OnItemSelect;
                this.Navigation.PushAsync(dropDown);
            }
        }

       
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
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

        public static BindableProperty EntryHintProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, string>(ctrl => ctrl.EntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
                    ctrl.EntryHint = newValue;
                });

        public string EntryHint
        {
            get { return (string)GetValue(EntryHintProperty); }
            set
            {
                SetValue(EntryHintProperty, value);
                EntryValue.Placeholder = value;
            }
        }

        public static BindableProperty EntryTextProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, string>(ctrl => ctrl.EntryText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
                    ctrl.EntryText = newValue;
                });

        public string EntryText
        {
            get { return (string)EntryValue.Text; }//GetValue(EntryTextProperty);
            set
            {
                SetValue(EntryTextProperty, value);
                EntryValue.Text = value;
            }
        }

       

        public static BindableProperty IsValidProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryDropdownHorizontal, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryDropdownHorizontal, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
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
        public static BindableProperty ItemSourceProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, Dictionary<string, string>>(ctrl => ctrl.ItemSource,
                defaultValue: new Dictionary<string, string>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
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

        public static BindableProperty SelectedItemProperty =
            BindableProperty.Create<LabelEntryDropdownHorizontal, KeyValuePair<string, string>?>(ctrl => ctrl.SelectedItem,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownHorizontal)bindable;
                    ctrl.SelectedItem = newValue;
                });

        public KeyValuePair<string, string>? SelectedItem
        {
            get { return (KeyValuePair<string, string>?)GetValue(SelectedItemProperty); }
            set
            {
                SetValue(SelectedItemProperty, value);
                
            }
        }
    }
}

