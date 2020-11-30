using ODISMember.CustomControls;
using ODISMember.iOS.Renderer;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer(typeof(CustomPicker), typeof(CustomPickerRenderer))]
namespace ODISMember.iOS.Renderer
{

	public class CustomPickerRenderer: PickerRenderer
    {
		protected override void OnElementChanged(ElementChangedEventArgs<Picker> e)
        {
            base.OnElementChanged(e);

            var view = e.NewElement as CustomPicker;

            if (this.Control != null && view!=null)
            {
                if (view.PickerTextAlignment == TextAlignment.Start)
                {
                    Control.TextAlignment = UITextAlignment.Left;
                }
                else if (view.PickerTextAlignment == TextAlignment.Center) {
                    Control.TextAlignment = UITextAlignment.Center;
                }
                else if (view.PickerTextAlignment == TextAlignment.End)
                {
                    Control.TextAlignment = UITextAlignment.Right;
                }

                if (view.Font != Font.Default)
                {
                    UIFont uiFont;
                    if (view.Font != Font.Default && (uiFont = view.Font.ToUIFont()) != null)
                        Control.Font = uiFont;
                }


            }
        }


        void ElementOnPropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            
            var view = (CustomPicker)Element;
            if (this.Control != null && view != null)
            {
                if (view.PickerTextAlignment == TextAlignment.Start)
                {
                    Control.TextAlignment = UITextAlignment.Left;
                }
                else if (view.PickerTextAlignment == TextAlignment.Center)
                {
                    Control.TextAlignment = UITextAlignment.Center;
                }
                else if (view.PickerTextAlignment == TextAlignment.End)
                {
                    Control.TextAlignment = UITextAlignment.Right;
                }

                switch (e.PropertyName)
                {
                    case "Font":
                        if (view.Font != Font.Default)
                        {
                            UIFont uiFont;
                            if (view.Font != Font.Default && (uiFont = view.Font.ToUIFont()) != null)
                                Control.Font = uiFont;
                        }
                        break;
                }


            }
        }

       
    }
}