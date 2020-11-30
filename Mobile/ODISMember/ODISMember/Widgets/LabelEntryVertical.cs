using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using ODISMember.Classes;
using FFImageLoading.Forms;

namespace ODISMember.Widgets
{
    public partial class LabelEntryVertical : StackLayout
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
        public StackLayout StackBackground;
       public StackLayout stackTitle;

        public LabelEntryVertical()
        {
            this.Orientation = StackOrientation.Vertical;
            this.Spacing = 0;
           
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["HeaderLineStyle"],
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
            EntryValue.LeftSwipe =(object s, EventArgs e)=>{

            };
            EntryValue.RightSwipe = (object s, EventArgs e) => {

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
            StackBackground = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.White,
                Padding = new Thickness(5)
            };

            EntryValue.TextChanged += (object sender, TextChangedEventArgs e) => {
                EntryText = e.NewTextValue;
            };
            EntryValue.TextChanged += EntryValue_TextChanged;

            StackBackground.Children.Add(EntryValue);
            stackTitle = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.Transparent,
                Padding = new Thickness(8)
            };
            stackTitle.Children.Add(LabelTitle);


            this.Children.Add(stackTitle);
            this.Children.Add(StackBackground);
            this.Children.Add(LabelError);
        }

        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            EntryText = e.NewTextValue;
        }
        public bool onValidate()
        {
            Validate.Invoke(new object(), EventArgs.Empty);
            return IsValid;
        }
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelEntryVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
            BindableProperty.Create<LabelEntryVertical, string>(ctrl => ctrl.EntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
            BindableProperty.Create<LabelEntryVertical, string>(ctrl => ctrl.EntryText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
                    ctrl.EntryText = newValue;
                });

        public string EntryText
        {
            get { return (string)EntryValue.Text; }//GetValue(EntryTextProperty);
            set
            {
                SetValue(EntryTextProperty, value);
                if (!string.IsNullOrEmpty(value))
                    EntryValue.Text = value;
            }
        }
        public static BindableProperty IsPasswordEntryProperty =
            BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsPasswordEntry,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
                    ctrl.IsPasswordEntry = newValue;
                });

        public bool IsPasswordEntry
        {
            get { return (bool)GetValue(IsPasswordEntryProperty); }
            set
            {
                SetValue(IsPasswordEntryProperty, value);
                EntryValue.IsPassword = value;
            }
        }

        public static BindableProperty KeyboardEntryProperty =
            BindableProperty.Create<LabelEntryVertical, Keyboard>(ctrl => ctrl.KeyboardEntry,
                defaultValue: Keyboard.Text,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryVertical)bindable;
                    ctrl.KeyboardEntry = newValue;
                });

        public Keyboard KeyboardEntry
        {
            get { return (Keyboard)GetValue(KeyboardEntryProperty); }
            set
            {
                SetValue(KeyboardEntryProperty, value);
                EntryValue.Keyboard = value;
            }
        }

        public static BindableProperty IsValidProperty =
            BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
            BindableProperty.Create<LabelEntryVertical, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
            BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
                    stackTitle.HeightRequest = 0;
                    stackTitle.Padding = 0;
                }
            }
        }

        public static BindableProperty IsLeftAlignProperty =
            BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsLeftAlign,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryVertical)bindable;
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
                }
            }
        }

        public static BindableProperty IsEntryContentLeftAlignProperty =
           BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsEntryContentLeftAlign,
               defaultValue: false,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) => {
                   var ctrl = (LabelEntryVertical)bindable;
                   ctrl.IsEntryContentLeftAlign = newValue;
               });

        public bool IsEntryContentLeftAlign
        {
            get { return (bool)GetValue(IsEntryContentLeftAlignProperty); }
            set
            {
                SetValue(IsEntryContentLeftAlignProperty, value);
                if (value == true)
                {
                    this.EntryValue.XAlign = TextAlignment.Start;
                }
            }
        }

        public static BindableProperty IsRemoveWhiteBackgroundProperty =
           BindableProperty.Create<LabelEntryVertical, bool>(ctrl => ctrl.IsRemoveWhiteBackground,
               defaultValue: false,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) => {
                   var ctrl = (LabelEntryVertical)bindable;
                   ctrl.IsRemoveWhiteBackground = newValue;
               });

        public bool IsRemoveWhiteBackground
        {
            get { return (bool)GetValue(IsRemoveWhiteBackgroundProperty); }
            set
            {
                SetValue(IsRemoveWhiteBackgroundProperty, value);
                if (value == true)
                {
                    this.StackBackground.BackgroundColor = Color.Transparent;
                    this.Padding = new Thickness(10, 5, 10, 5);
                    this.StackBackground.Padding = new Thickness(0);
                }
            }
        }

    }
}

