using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Text;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer(typeof(Button), typeof(CustomButtonRenderer))]
namespace ODISMember.iOS.Renderers
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
                var fontName = Path.GetFileNameWithoutExtension(view.Font.FontFamily);

                Control.Font = UIFont.FromName(fontName, (float)view.Font.FontSize);
            }
        }
    }
}
