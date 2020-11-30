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
using System.IO;
using Android.Graphics;
using System.ComponentModel;
using ODISMember.CustomControls;
using ODISMember.Droid.Renderers;
using ODISMember.Droid.ResizeImage;

[assembly: ExportRenderer(typeof(CropView), typeof(CropViewRenderer))]
namespace ODISMember.Droid.Renderers
{
    public class CropViewRenderer : PageRenderer
    {
        string ImagePath;        
        protected override void OnElementChanged(ElementChangedEventArgs<Page> e)
        {
            base.OnElementChanged(e);
            var page = e.NewElement as CropView;
            ImagePath = page.ImagePath;
            
            GetCorpImage();
        }

        public void GetCorpImage()
        {
            try
            {   
                Intent intent = new Intent(Android.App.Application.Context, typeof(CorpImage));
                intent.SetFlags(ActivityFlags.NewTask);
                intent.PutExtra("image-path", ImagePath);
                intent.PutExtra("scale", false);
                intent.PutExtra("return-data", true);
                
                Android.App.Application.Context.StartActivity(intent);                
            }
            catch (Exception ex)
            {

                throw;
            }
        }

        protected override void OnDetachedFromWindow()
        {
            if(Global.CroppedImage != null)
            {
                var page = base.Element as CropView;
                page.DidCrop = true;
            }

            base.OnDetachedFromWindow();
        }
    }
}