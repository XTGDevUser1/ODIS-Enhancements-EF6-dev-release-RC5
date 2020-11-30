using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using Android.App;
using Android.Content;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Android.Widget;
using Xamarin.Forms;

using Xamarin.Forms.Platform.Android;
using ODISMember.CustomControls;
using ODISMember.Droid.Renderer;
using Android.Content.Res;
using Android.Graphics;

[assembly: ExportRenderer(typeof(CustomPicker), typeof(CustomPickerRenderer))]
namespace ODISMember.Droid.Renderer
{

    //  using NativeRadioButton = RadioButton;

    public class CustomPickerRenderer : PickerRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Picker> e)
        {
            base.OnElementChanged(e);



            var view = e.NewElement as CustomPicker;

            if (this.Control != null && view != null)
            {
                Android.Graphics.Color adColor = Xamarin.Forms.Color.Black.ToAndroid();
                this.Control.SetTextColor(adColor);

                if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.Start)
                {
                    Control.Gravity = GravityFlags.Start;
                }
                else if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.Center)
                {
                    Control.Gravity = GravityFlags.Center;
                }
                else if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.End)
                {
                    Control.Gravity = GravityFlags.End;
                }

                if (view.Font != Font.Default) {
                    Control.TextSize = view.Font.ToScaledPixel();
                    var normalFont = Typeface.CreateFromAsset(Context.Assets, "fonts/" + view.Font.FontFamily + ".ttf");
                    this.Control.SetTypeface(normalFont, TypefaceStyle.Normal);
                }
            }
        }


        void ElementOnPropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
			//base.OnElementPropertyChanged(e);
            var view = (CustomPicker)Element;

            if (this.Control != null && view != null)
            {
                Android.Graphics.Color adColor = Xamarin.Forms.Color.Black.ToAndroid();
                this.Control.SetTextColor(adColor);

                if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.Start)
                {
                    Control.Gravity = GravityFlags.Start;
                }
                else if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.Center)
                {
                    Control.Gravity = GravityFlags.Center;
                }
                else if (view.PickerTextAlignment == Xamarin.Forms.TextAlignment.End)
                {
                    Control.Gravity = GravityFlags.End;
                }
            }
            switch (e.PropertyName)
            {
                case "Font":
                    if (view.Font != Font.Default)
                    {
                        Control.TextSize = view.Font.ToScaledPixel();
                        var normalFont = Typeface.CreateFromAsset(Context.Assets, "fonts/" + view.Font.FontFamily + ".ttf");
                        this.Control.SetTypeface(normalFont, TypefaceStyle.Normal);
                    }
                    break;
            }
            
        }
    }
}