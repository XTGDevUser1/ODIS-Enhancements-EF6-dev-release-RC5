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
using ODISMember.Interfaces;
using Xamarin.Forms;
using ODISMember.Droid.Renderers;
using Android.Graphics;
using System.IO;

[assembly: Dependency(typeof(ScreenshotManager))]
namespace ODISMember.Droid.Renderers
{
    public class ScreenshotManager : IScreenshotManager
    {
        public static Activity Activity { get; set; }
        public byte[] CaptureAsync()
        {
            if (Activity == null)
            {
                throw new Exception("You have to set ScreenshotManager.Activity in your Android project");
            }

            var view = Activity.Window.DecorView;
            view.DrawingCacheEnabled = true;

            Bitmap bitmap = view.GetDrawingCache(true);
            byte[] bitmapData;

            using (var stream = new MemoryStream())
            {
                bitmap.Compress(Bitmap.CompressFormat.Png, 0, stream);
                bitmapData = stream.ToArray();
            }
            view.DrawingCacheEnabled = false;
            return bitmapData;
        }
    }
}