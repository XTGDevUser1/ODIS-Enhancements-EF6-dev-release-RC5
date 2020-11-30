using System;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{
    public class CropView : ContentPage
    {
        public byte[] Image;
        public string ImagePath;
        public Action RefreshAction;
        public bool DidCrop = false;

        /// <summary>
        /// Initializes a new instance of the <see cref="CropView"/> class.
        /// NOTE: This constructor used for iOS
        /// </summary>
        /// <param name="imageAsByte">The image as byte.</param>
        /// <param name="refreshAction">The refresh action.</param>
        public CropView(byte[] imageAsByte, Action refreshAction)
        {
            NavigationPage.SetHasNavigationBar(this, false);
            BackgroundColor = Color.Black;
            Image = imageAsByte;

            RefreshAction = refreshAction;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CropView"/> class.
        /// NOTE: This constructor used for Android
        /// </summary>
        /// <param name="imagePath">The image path.</param>
        /// <param name="refreshAction">The refresh action.</param>
        public CropView(string imagePath, Action refreshAction)
        {
            NavigationPage.SetHasNavigationBar(this, false);
            BackgroundColor = Color.Black;
            ImagePath = imagePath;

            RefreshAction = refreshAction;
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            if (DidCrop)
            {
                RefreshAction.Invoke();
            }
        }
    }
}

