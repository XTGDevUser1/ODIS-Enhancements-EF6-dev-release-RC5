using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{
    public class CustomPicker : Picker
    {
        //TextAlignment
        public static BindableProperty PickerTextAlignmentProperty =
            BindableProperty.Create<CustomPicker, TextAlignment>(ctrl => ctrl.PickerTextAlignment,
                defaultValue: TextAlignment.Start,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (CustomPicker)bindable;
                    ctrl.PickerTextAlignment = newValue;
                });

        public TextAlignment PickerTextAlignment
        {
            get { return (TextAlignment)GetValue(PickerTextAlignmentProperty); }
            set
            {
                SetValue(PickerTextAlignmentProperty, value);
            }
        }
        public static BindableProperty FontProperty =
            BindableProperty.Create<CustomPicker, Font>(ctrl => ctrl.Font,
                defaultValue: Font.Default,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (CustomPicker)bindable;
                    ctrl.Font = newValue;
                });

        public Font Font
        {
            get { return (Font)GetValue(FontProperty); }
            set
            {
                SetValue(FontProperty, value);
            }
        }
       
    }
}
