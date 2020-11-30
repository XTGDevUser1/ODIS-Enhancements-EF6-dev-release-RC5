using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using ODISMember.Classes;
using FFImageLoading.Forms;

namespace ODISMember.Widgets
{
    public partial class LabelEntryHorizontal : StackLayout
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
        public LabelEntryHorizontal()
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
            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor,
                LineBreakMode = LineBreakMode.WordWrap
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
            EntryValue.TextChanged += EntryValue_TextChanged;
            //StackLayout stack = new StackLayout()
            //{
                
            //    Orientation = StackOrientation.Horizontal
            //};
            EntryValue.LeftSwipe = (object s, EventArgs e) => {

            };
            EntryValue.RightSwipe = (object s, EventArgs e) => {

            };

            //stack.Children.Add(EntryValue);
            //sstack.Children.Add(ImageValidate);

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
            grid.Children.Add(LabelError,0,2,1,2);
            
            this.Children.Add(grid);
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
            BindableProperty.Create<LabelEntryHorizontal, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, string>(ctrl => ctrl.EntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, string>(ctrl => ctrl.EntryText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
                    ctrl.EntryText = newValue;
                });

        public string EntryText
        {
            get { return (string)EntryValue.Text; }
            set
            {
                SetValue(EntryTextProperty, value);
                if (!string.IsNullOrEmpty(value))
                    EntryValue.Text = value;
            }
        }
        public static BindableProperty IsPasswordEntryProperty =
            BindableProperty.Create<LabelEntryHorizontal, bool>(ctrl => ctrl.IsPasswordEntry,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, Keyboard>(ctrl => ctrl.KeyboardEntry,
                defaultValue: Keyboard.Text,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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
            BindableProperty.Create<LabelEntryHorizontal, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelEntryHorizontal)bindable;
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

    }
}

