using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Widgets
{
    public partial class ProfileLabelValueVertical : StackLayout
    {
        public ExtendedLabel LabelValue
        {
            get;
            set;
        }
        public ExtendedLabel LabelTitle
        {
            get;
            set;
        }
        public ProfileLabelValueVertical() {
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["HeaderLineStyle"],
                HorizontalTextAlignment = TextAlignment.Center
            };
            LabelValue = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["ProfileLabelValueVertical_ValueStyle"],
                HorizontalTextAlignment = TextAlignment.Start
                
            };
            StackLayout stackValue = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.White,
                Padding =  new Thickness(5,15,5,15)
            };
            StackLayout stackTitle = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.Transparent,
                Padding = new Thickness(8)
            };
            stackTitle.Children.Add(LabelTitle);
            stackValue.Children.Add(LabelValue);
            this.Children.Add(stackTitle);
            this.Children.Add(stackValue);
        }
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<ProfileLabelValueVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (ProfileLabelValueVertical)bindable;
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


        public static BindableProperty ValueTextProperty =
            BindableProperty.Create<ProfileLabelValueVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (ProfileLabelValueVertical)bindable;
                    ctrl.ValueText = newValue;
                });

        public string ValueText
        {
            get { return (string)GetValue(ValueTextProperty); }
            set
            {
                SetValue(ValueTextProperty, value);
                LabelValue.Text = value;
            }
        }
    }
}
