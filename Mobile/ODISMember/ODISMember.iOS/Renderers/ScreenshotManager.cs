﻿using ODISMember.Interfaces;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(ScreenshotManager))]
namespace ODISMember.iOS.Renderers
{
    public class ScreenshotManager : IScreenshotManager
    {
        public byte[] CaptureAsync()
        {
            var view = UIApplication.SharedApplication.KeyWindow.RootViewController.View;

            UIGraphics.BeginImageContext(view.Frame.Size);
            view.DrawViewHierarchy(view.Frame, true);
            var image = UIGraphics.GetImageFromCurrentImageContext();
            UIGraphics.EndImageContext();

            using (var imageData = image.AsPNG())
            {
                var bytes = new byte[imageData.Length];
                System.Runtime.InteropServices.Marshal.Copy(imageData.Bytes, bytes, 0, Convert.ToInt32(imageData.Length));
                return bytes;
            }
        }
    }
}
