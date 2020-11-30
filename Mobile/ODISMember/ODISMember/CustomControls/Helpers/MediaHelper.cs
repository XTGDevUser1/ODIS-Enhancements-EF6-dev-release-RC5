using Plugin.Media;
using Plugin.Media.Abstractions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.CustomControls.Helpers
{
    public static class MediaHelper
    {
        public static async Task<MediaFile> TakePhoto() {
            await CrossMedia.Current.Initialize();
            if (!CrossMedia.Current.IsCameraAvailable || !CrossMedia.Current.IsTakePhotoSupported)
            {
                ToastHelper.ShowErrorToast("No Camera", ":( No camera available.");
                return null;
            }
            var file = await CrossMedia.Current.TakePhotoAsync(new Plugin.Media.Abstractions.StoreCameraMediaOptions
            {
                Directory = "sample",
                Name = "sample.png"
            });
            return file;
        }
        public static async Task<MediaFile> OpenGallery()
        {
            await CrossMedia.Current.Initialize();
            var file = await CrossMedia.Current.PickPhotoAsync();
            return file;
        }
    }
}
