using Foundation;
using ODISMember.CustomControls;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;
using XLabs.Forms.Controls;

//[assembly: ExportRenderer(typeof(CustomEditor), typeof(CustomEditorRenderer))]
namespace ODISMember.iOS.Renderers
{
   public class CustomEditorRenderer : ExtendedEditorRenderer
    {
        private string Placeholder { get; set; }

        protected override void OnElementChanged(ElementChangedEventArgs<Editor> e)
        {
            base.OnElementChanged(e);
            var element = this.Element as CustomEditor;

            if (Control != null && element != null)
            {
                
                //Placeholder = element.Placeholder;
                if (string.IsNullOrEmpty(Control.Text)) {
                    Control.TextColor = UIColor.LightGray;
                    Control.Text = Placeholder;
                }
                //Control.ShouldBeginEditing += (UITextView textView) =>
                //{

                //    if (textView.Text == Placeholder)
                //    {
                //        //textView.Text = "";
                //        //textView.TextColor = UIColor.Black; // Text Color

                //        //textView.BecomeFirstResponder();
                //        var indexToSet = 0; 
                //        var positionToSet = textView.GetPosition(textView.BeginningOfDocument, indexToSet);
                //        textView.SelectedTextRange = textView.GetTextRange(positionToSet, positionToSet);

                //    }

                //    return true;
                //};

                //Control.ShouldEndEditing += (UITextView textView) => {
                //    if (string.IsNullOrEmpty(textView.Text))
                //    {
                //        textView.Text = Placeholder;
                //        textView.TextColor = UIColor.LightGray; // Placeholder Color

                //        var indexToSet = 0;
                //        var positionToSet = textView.GetPosition(textView.BeginningOfDocument, indexToSet);
                //        textView.SelectedTextRange = textView.GetTextRange(positionToSet, positionToSet);

                //    }

                //    return true;
                Control.ShouldBeginEditing += (UITextView textView) => {
                    if (textView.Text == Placeholder)
                    {
                        textView.Text = "";
                        textView.TextColor = UIColor.Black; // Text Color
                    }

                    return true;
                };

                Control.ShouldEndEditing += (UITextView textView) => {
                    if (textView.Text == "")
                    {
                        textView.Text = Placeholder;
                        textView.TextColor = UIColor.LightGray; // Placeholder Color
                    }

                    return true;
                };
                
                Control.Changed += (object s, EventArgs ev) => {
                    UITextView textView = (UITextView)s;
                    if (textView.Text == null || textView.Text.Trim().Length == 0)
                    {
                        textView.Text = Placeholder;
                        textView.TextColor = UIColor.LightGray; // Placeholder Color

                        var indexToSet = 0;
                        var positionToSet = textView.GetPosition(textView.BeginningOfDocument, indexToSet);
                        textView.SelectedTextRange = textView.GetTextRange(positionToSet, positionToSet);

                    }
                    else
                    {
                        textView.Text = textView.Text.Replace(Placeholder, string.Empty);
                        textView.TextColor = UIColor.Black;
                    }
                };


                }
        }
        
    }
}
