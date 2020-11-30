using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.CustomControls;
using ODISMember.Classes;
using ODISMember.Entities;

namespace ODISMember.Widgets
{
    public class LabelDateVertical : StackLayout
    {
        public ExtendedLabel LabelTitle
        {
            get;
            set;
        }
        public CustomDatePicker DatePicker
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

        public StackLayout stack;
        public LabelDateVertical()
        {
            this.Orientation = StackOrientation.Vertical;
            this.Spacing = 0;
           // Padding = new Thickness(10, 5, 10, 5);
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
            DatePicker = new CustomDatePicker
            {
                Format = "M/d/yyyy",
                VerticalOptions = LayoutOptions.CenterAndExpand,
                HorizontalOptions = LayoutOptions.FillAndExpand
            };
            DatePicker.DateEntry.TextChanged += (object sender, TextChangedEventArgs e) =>
            {
                this.Date = Convert.ToDateTime(e.NewTextValue);
            };
            //StackLayout stack = new StackLayout()
            //{
            //    HorizontalOptions = LayoutOptions.FillAndExpand,
            //    BackgroundColor = Color.White,
            //    Padding = new Thickness(5)
            //};
            StackLayout stackValue = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.White,
                Padding = new Thickness(5,5,5,0)
            };
            StackLayout stackTitle = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.Transparent,
                Padding = new Thickness(8)
            };
            stackValue.Children.Add(DatePicker);
            stackTitle.Children.Add(LabelTitle);
            this.Children.Add(stackTitle);
            this.Children.Add(stackValue);
            this.Children.Add(LabelError);


        }
        public string SelectedDate()
        {
            return DatePicker.GetSelectedDate();
        }
        public bool onValidate()
        {
            Validate.Invoke(new object(), EventArgs.Empty);
            return IsValid;
        }
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelDateVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
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

        public static BindableProperty IsLeftAlignProperty =
            BindableProperty.Create<LabelDateVertical, bool>(ctrl => ctrl.IsLeftAlign,
                defaultValue: false,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
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
                    this.DatePicker.HorizontalOptions = LayoutOptions.Fill;
                    this.DatePicker.DateEntry.XAlign = TextAlignment.Start;
                    this.LabelTitle.HorizontalTextAlignment = TextAlignment.Start;
                    this.LabelTitle.HorizontalOptions = LayoutOptions.StartAndExpand;
                    this.Padding = new Thickness(0);// new Thickness(0, 0, 20, 0);

                }
            }
        }


        public static BindableProperty IsValidProperty =
            BindableProperty.Create<LabelDateVertical, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
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
            BindableProperty.Create<LabelDateVertical, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
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

        public static BindableProperty DateEntryHintProperty =
            BindableProperty.Create<LabelDateVertical, string>(ctrl => ctrl.DateEntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
                    ctrl.DateEntryHint = newValue;
                });

        public string DateEntryHint
        {
            get { return (string)GetValue(DateEntryHintProperty); }
            set
            {
                SetValue(DateEntryHintProperty, value);
                DatePicker.DateEntry.Placeholder = value;
            }
        }

        public static BindableProperty IsLabelVisibleProperty =
            BindableProperty.Create<LabelDateVertical, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
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

        public static BindableProperty DateProperty =
            BindableProperty.Create<LabelDateVertical, DateTime?>(ctrl => ctrl.Date,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDateVertical)bindable;
                    ctrl.Date = newValue;
                });

        public DateTime? Date
        {
            get { return (DateTime?)GetValue(DateProperty); }
            set
            {
                SetValue(DateProperty, value);
                if (value != null)
                {
                    DatePicker.DateEntry.Text = value.Value.ToString(Constants.DateFormat);
                    DatePicker.Date = value.Value;
                }

            }
        }
        public static BindableProperty IsEntryContentLeftAlignProperty =
          BindableProperty.Create<LabelDateVertical, bool>(ctrl => ctrl.IsEntryContentLeftAlign,
              defaultValue: false,
              defaultBindingMode: BindingMode.TwoWay,
              propertyChanging: (bindable, oldValue, newValue) =>
              {
                  var ctrl = (LabelDateVertical)bindable;
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
                    if (this.DatePicker != null && this.DatePicker.DateEntry != null)
                    {
                        this.DatePicker.DateEntry.XAlign = TextAlignment.Start;
                    }
                }
            }
        }


    }
}

