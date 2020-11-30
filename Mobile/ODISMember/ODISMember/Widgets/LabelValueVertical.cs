using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Widgets
{
    public partial class LabelValueVertical: StackLayout
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
        public LabelValueVertical() {
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["LabelValueVertical_LabelStyle"],
                HorizontalTextAlignment = TextAlignment.Start
            };
            LabelValue = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["LabelValueVertical_ValueStyle"],
                HorizontalTextAlignment = TextAlignment.Start
            };
            this.Children.Add(LabelTitle);
            this.Children.Add(LabelValue);
        }
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelValueVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelValueVertical)bindable;
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
            BindableProperty.Create<LabelValueVertical, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelValueVertical)bindable;
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
