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
    public partial class LabelEntryDropdownVertical : StackLayout
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
        public Func<Dictionary<string, string>, Dictionary<string, string>> LoadItemSource;
        public Dictionary<string, string> LoadItemSourceParam;
        public string Key
        {
            get;
            set;
        }
        public string Value
        {
            get;
            set;
        }

        //public KeyValuePair<string, string>? SelectedItem { get; set; }
        // public StackLayout stack;
        public event EventHandler<TextChangedEventArgs> OnDropDownSelection;
        public LabelEntryDropdownVertical()
        {
            this.Orientation = StackOrientation.Vertical;
            this.Spacing = 0;
            Padding = new Thickness(10, 5, 10, 5);

            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand
            };
            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor
            };
            EntryValue = new ExtendedEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                HasBorder = true,
                XAlign = TextAlignment.Center,
                TextColor = ColorResources.EntryLabelValueColor,
                BackgroundColor = Color.White
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
            //stack = new StackLayout()
            //{
            //    Orientation = StackOrientation.Horizontal,
            //    Padding = new Thickness(20, 0, 0, 0)
            //};

            EntryValue.TextChanged += EntryValue_TextChanged;
            EntryValue.LeftSwipe = (object s, EventArgs e) =>
            {

            };
            EntryValue.RightSwipe = (object s, EventArgs e) =>
            {

            };
            // stack.Children.Add(EntryValue);
            // stack.Children.Add(ImageValidate);
            this.Children.Add(LabelTitle);
            this.Children.Add(EntryValue);
            this.Children.Add(LabelError);
        }
        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (OnDropDownSelection != null)
            {
                OnDropDownSelection.Invoke(sender, e);
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
                dropDown.LoadItemSource = this.LoadItemSource;
                dropDown.LoadItemSourceParam = this.LoadItemSourceParam;
                this.Navigation.PushAsync(dropDown);
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
                else
                {
                    if (IsShowValueInEntry)
                    {
                        EntryValue.Text = SelectedItem.Value.Value;
                    }
                    else
                    {
                        EntryValue.Text = SelectedItem.Value.Key;
                    }
                    this.Key = SelectedItem.Value.Key;
                    this.Value = SelectedItem.Value.Value;
                }
                EntryValue.Unfocus();
            }
        }
        public bool onValidate()
        {
            Validate.Invoke(new object(), EventArgs.Empty);
            return IsValid;
        }
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelEntryDropdownVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
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
            BindableProperty.Create<LabelEntryDropdownVertical, string>(ctrl => ctrl.EntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
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
            BindableProperty.Create<LabelEntryDropdownVertical, string>(ctrl => ctrl.EntryText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
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
            BindableProperty.Create<LabelEntryDropdownVertical, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
                    ctrl.IsValid = newValue;
                });

        public bool IsValid
        {
            get { return (bool)GetValue(IsValidProperty); }
            set
            {
                SetValue(IsValidProperty, value);
                //ImageValidate.HeightRequest = 20;
                //ImageValidate.Source =	(value ? "success.png" : "error.png");

            }
        }

        public static BindableProperty EntryErrorMessageProperty =
            BindableProperty.Create<LabelEntryDropdownVertical, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
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
            BindableProperty.Create<LabelEntryDropdownVertical, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
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

        public static BindableProperty IsLeftAlignProperty =
            BindableProperty.Create<LabelEntryDropdownVertical, bool>(ctrl => ctrl.IsLeftAlign,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
                    ctrl.IsLeftAlign = newValue;
                });

        public bool IsLeftAlign
        {
            get { return (bool)GetValue(IsLeftAlignProperty); }
            set
            {
                SetValue(IsLeftAlignProperty, value);
                if (value == true)
                {
                    this.EntryValue.XAlign = TextAlignment.Start;
                    this.LabelTitle.HorizontalTextAlignment = TextAlignment.Start;
                    this.LabelTitle.HorizontalOptions = LayoutOptions.StartAndExpand;
                    //this.stack.Padding = new Thickness(0);
                }
            }
        }
        public static BindableProperty ItemSourceProperty =
           BindableProperty.Create<LabelEntryDropdownVertical, Dictionary<string, string>>(ctrl => ctrl.ItemSource,
               defaultValue: new Dictionary<string, string>(),
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) =>
               {
                   var ctrl = (LabelEntryDropdownVertical)bindable;
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
            BindableProperty.Create<LabelEntryDropdownVertical, KeyValuePair<string, string>?>(ctrl => ctrl.SelectedItem,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
                    ctrl.SelectedItem = newValue;

                   
                });

        public KeyValuePair<string, string>? SelectedItem
        {
            get { return (KeyValuePair<string, string>?)GetValue(SelectedItemProperty); }
            set
            {
                SetValue(SelectedItemProperty, value);
                if (value != null)
                {
                    Key = value.Value.Key;
                    Value = value.Value.Value;
                }
            }
        }
        public static BindableProperty IsShowValueInEntryProperty =
            BindableProperty.Create<LabelEntryDropdownVertical, bool>(ctrl => ctrl.IsShowValueInEntry,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryDropdownVertical)bindable;
                    ctrl.IsShowValueInEntry = newValue;
                });

        public bool IsShowValueInEntry
        {
            get { return (bool)GetValue(IsShowValueInEntryProperty); }
            set
            {
                SetValue(IsShowValueInEntryProperty, value);
            }
        }
        //IsShowValueInEntry
    }
}
