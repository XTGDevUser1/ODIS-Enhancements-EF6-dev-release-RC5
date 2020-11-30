using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using ODISMember.Classes;

namespace ODISMember.Widgets
{
    public partial class ImageTextHeader : StackLayout
    {
        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<ImageTextHeader, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (ImageTextHeader)bindable;
                    ctrl.LabelText = newValue;
                });
        public string LabelText
        {
            get { return (string)GetValue(LabelTextProperty); }
            set
            {
                SetValue(LabelTextProperty, value);
                label.Text = value;
            }
        }

        public static BindableProperty ImageSourceProperty =
            BindableProperty.Create<ImageTextHeader, string>(ctrl => ctrl.ImageSource,
				defaultValue:ImagePathResources.DefaultIcon,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (ImageTextHeader)bindable;
                    ctrl.ImageSource = newValue;
                });
        public string ImageSource
        {
            get { return (string)GetValue(ImageSourceProperty); }
            set
            {
                SetValue(ImageSourceProperty, value);
                image.Source = value;
            }
        }

            

        public ImageTextHeader()
        {
            InitializeComponent();

            var tapGestureRecognizerImage = new TapGestureRecognizer() { NumberOfTapsRequired = 1 };
            tapGestureRecognizerImage.Tapped += OnImageClick;
            image.GestureRecognizers.Add(tapGestureRecognizerImage);
        }

        public void OnImageClick(object sender, EventArgs e)
        {
            //Navigation.PopAsync();
        }
    }
}
