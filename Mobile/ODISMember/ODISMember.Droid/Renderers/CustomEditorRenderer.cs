using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using XLabs.Forms.Controls;
using Android.App;
using Android.Content;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Android.Widget;
using Xamarin.Forms.Platform.Android;
using ODISMember.CustomControls;
using Xamarin.Forms;
using System.ComponentModel;
using ODISMember.Droid.Renderers;

//[assembly: ExportRenderer(typeof(CustomEditor), typeof(CustomEditorRenderer))]
namespace ODISMember.Droid.Renderers
{
    public class CustomEditorRenderer : ExtendedEditorRenderer
    {
        // private string Placeholder { get; set; }
        public CustomEditorRenderer()
        {
        }
        protected override void OnElementChanged(ElementChangedEventArgs<Editor> e)
        {
            base.OnElementChanged(e);

            if (e.NewElement != null)
            {
                var element = e.NewElement as CustomEditor;
                //this.Control.Hint = element.Placeholder;
            }
        }

        protected override void OnElementPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            base.OnElementPropertyChanged(sender, e);

            //if (e.PropertyName == CustomEditor.PlaceholderProperty.PropertyName)
            //{
            //    var element = this.Element as CustomEditor;
            //    this.Control.Hint = element.Placeholder;
            //}
        }
    }
}