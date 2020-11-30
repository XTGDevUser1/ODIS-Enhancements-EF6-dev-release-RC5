using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using Android.App;
using Android.Content;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Xamarin.Forms;
using ODISMember.CustomControls;
using ODISMember.Droid.Renderers;
using Xamarin.Forms.Platform.Android;
using System.ComponentModel;
using Android.Graphics;

[assembly: ExportRenderer(typeof(Button), typeof(CustomButtonRenderer))]
namespace ODISMember.Droid.Renderers
{
    public class CustomButtonRenderer : ButtonRenderer
    {

        protected override void OnElementChanged(ElementChangedEventArgs<Button> e)
        {
            base.OnElementChanged(e);

            var view = e.NewElement as Button;
            if (this.Control != null && view != null)
            {
                SetFont(view);

            }
        }
        protected override void OnElementPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            base.OnElementPropertyChanged(sender, e);
            var view = (Button)Element;
            switch (e.PropertyName)
            {
                case "Font":
                    SetFont(view);
                    break;
            }
        }
        private void SetFont(Button view)
        {
            if (view.Font != Font.Default)
            {

                if (!string.IsNullOrEmpty(view.Font.FontFamily))
                {
                    var normalFont = Typeface.CreateFromAsset(Context.Assets, "fonts/" + view.Font.FontFamily + ".ttf");
                    this.Control.SetTypeface(normalFont, TypefaceStyle.Normal);

                }
                else
                {
                    if (view.FontAttributes == FontAttributes.Bold)
                    {
                        this.Control.SetTypeface(null, TypefaceStyle.Bold);
                        if (view.BackgroundColor != null)
                        {
                            this.Control.SetBackgroundColor(view.BackgroundColor.ToAndroid());
                        }
                    }
                }
                if (view.Font.FontSize != 0)
                {
                    this.Control.TextSize = view.Font.ToScaledPixel();
                }
            }
        }
    }
}