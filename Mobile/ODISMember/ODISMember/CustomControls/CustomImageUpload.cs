using FFImageLoading.Forms;
using FFImageLoading.Transformations;
using FFImageLoading.Work;
using ODISMember.Classes;
using ODISMember.Entities;
using ODISMember.Interfaces;
using Plugin.Media;
using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{

    public class CustomImageUpload : StackLayout
    {
        public bool IsDefaultImage
        {
            get;
            set;
        }
        public CachedImage CustomImage
        {
            get;
            set;
        }
        public Button AddOrRemove
        {
            get;
            set;
        }
        public Button TakePhoto
        {
            get;
            set;
        }
        public Button OpenGallery
        {
            get;
            set;
        }
        public RelativeLayout ImageLayout
        {
            get;
            set;
        }
        StackLayout ButtonLayout;
        StackLayout ImgRemoveLayout;
        MemberHelper memberHelper = new MemberHelper();
        ContentPage ParentPage;
        public event EventHandler<CachedImageEvents.SuccessEventArgs> OnImageSelect;
        public CustomImageUpload(ContentPage currentPage = null, bool isCircleImage = false)
        {
            ParentPage = currentPage;
            IsDefaultImage = false;
            CustomImage = new CachedImage()
            {
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
                Aspect = Aspect.Fill,
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false,
                ClassId = "NoImage"
            };
            CustomImage.Success += CustomImage_Success;
            if (isCircleImage)
            {
                CustomImage.Transformations = new System.Collections.Generic.List<ITransformation>() {
                    new CircleTransformation(),
                };
            }
            //RemoveCustomImage = new CustomImageButton()
            //{
            //    HorizontalOptions = LayoutOptions.End,
            //    VerticalOptions = LayoutOptions.Start,
            //    ImageUrl = ImagePathResources.RemoveImage,
            //    HeightRequest = 30,
            //    WidthRequest = 30,
            //    IsVisible = false,
            //    Opacity = 0.5
            //};
            AddOrRemove = new Button()
            {
                BackgroundColor = Color.Transparent,//FromHsla(0, 0, 0, 0.5),
                HorizontalOptions = LayoutOptions.FillAndExpand,
                VerticalOptions = LayoutOptions.FillAndExpand
            };
            //RemoveCustomImage.ImageClick += RemoveCustomImage_ImageClick;
            AddOrRemove.Clicked += AddOrRemove_Clicked;

            TakePhoto = new Button()
            {
                Text = "Take Photo",
                Style = (Style)Application.Current.Resources["BaseButtonStyle"],
            };
            TakePhoto.Clicked += TakePhoto_Clicked;
            OpenGallery = new Button()
            {
                Text = "Open Gallery",
                Style = (Style)Application.Current.Resources["BaseButtonStyle"],
            };
            OpenGallery.Clicked += OpenGallery_Clicked;
            ImageLayout = new RelativeLayout()
            {
                HorizontalOptions = LayoutOptions.Center
            };

            StackLayout imgLayout = new StackLayout()
            {
                BackgroundColor = Color.Transparent
            };
            ImgRemoveLayout = new StackLayout()
            {
                BackgroundColor = Color.Transparent
            };
            imgLayout.Children.Add(CustomImage);
            ImgRemoveLayout.Children.Add(AddOrRemove);
            ImageLayout.Children.Add(imgLayout,
                Constraint.Constant(0),
                Constraint.Constant(0),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
                }));

            ImageLayout.Children.Add(ImgRemoveLayout,
               Constraint.Constant(0),
                Constraint.Constant(0),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
                }));


            ButtonLayout = new StackLayout();
            ButtonLayout.Children.Add(TakePhoto);
            ButtonLayout.Children.Add(OpenGallery);

            this.Children.Add(ImageLayout);


        }

        private void CustomImage_Success(object sender, CachedImageEvents.SuccessEventArgs e)
        {
            if (OnImageSelect != null && !IsDefaultImage)
            {
                OnImageSelect(sender, e);
            }
        }

        private async void AddOrRemove_Clicked(object sender, EventArgs e)
        {
            if (CurrentPage != null)
            {
                string action = string.Empty;
                if (CustomImage.ClassId == null || string.IsNullOrEmpty(CustomImage.ClassId))
                {
                    action = await CurrentPage.DisplayActionSheet("Choose action", "Cancel", null, "Take Photo", "Open Gallery", "Delete Photo");
                }
                else
                {
                    action = await CurrentPage.DisplayActionSheet("Choose action", "Cancel", null, "Take Photo", "Open Gallery");
                }

                if (action == "Take Photo")
                {
                    TakePhoto_Clicked(new object(), EventArgs.Empty);
                }
                else if (action == "Open Gallery")
                {
                    OpenGallery_Clicked(new object(), EventArgs.Empty);
                }
                else if (action == "Delete Photo")
                {
                    RemoveImage();
                }
            }
        }


        void RemoveImage()
        {
            IsDefaultImage = false;
            CustomImage.Source = DefaultImageSource;
            CustomImage.ClassId = "NoImage";
        }

        public async Task<byte[]> GetImageBytes(int height, int width)
        {
            if (CustomImage.ClassId == "NoImage")
                return new byte[] { };
            else
            {
                return await CustomImage.GetImageAsPngAsync(width, height);
                //return await CustomImage.GetImageAsJpgAsync(90, width, height);
                //return await CustomImage.GetImageAsPngAsync();
            }
        }
        public void SetImageSouce(byte[] imageBytes)
        {
            IsDefaultImage = true;
            if (imageBytes != null && imageBytes.Length != 0)
            {
                CustomImage.Source = Xamarin.Forms.ImageSource.FromStream(() =>
                {
                    CustomImage.ClassId = null;
                    Stream stream = new MemoryStream(imageBytes);
                    return stream;
                });
            }
            else
            {
                CustomImage.ClassId = "NoImage";
                CustomImage.Source = DefaultImageSource;
            }
        }

        private async void OpenGallery_Clicked(object sender, EventArgs e)
        {

            Dictionary<Permission, PermissionStatus> permissions = await CrossPermissions.Current.RequestPermissionsAsync(new[] { Permission.Photos, Permission.Storage });
            PermissionStatus status = PermissionStatus.Unknown;
            if (Device.OS == TargetPlatform.iOS)
            {
                status = permissions[Permission.Photos];
            }
            else if (Device.OS == TargetPlatform.Android)
            {
                status = permissions[Permission.Storage];
            }
            await CrossMedia.Current.Initialize();
            if (status != PermissionStatus.Granted)
            {

                if (ParentPage != null)
                {
                    bool result = await ParentPage.DisplayAlert("", "Turn on photos permissions in the Settings to allow Roadside to use your photos", "Go To Settings", "Cancel");
                    if (result)
                    {
                        DependencyService.Get<IOpenSettings>().Opensettings();
                        return;
                    }
                }
                return;
            }

            var file = await CrossMedia.Current.PickPhotoAsync();
            if (file == null)
                return;

            ResizeImage(file);

            //IsDefaultImage = false;
            //CustomImage.Source = file.Path;
            //CustomImage.ClassId = null;
        }

        private async void TakePhoto_Clicked(object sender, EventArgs e)
        {
            Dictionary<Permission, PermissionStatus> permissions = await CrossPermissions.Current.RequestPermissionsAsync(new[] { Permission.Camera });
            PermissionStatus status = permissions[Permission.Camera];
            if (status != PermissionStatus.Granted)
            {
                if (ParentPage != null)
                {
                    bool result = await ParentPage.DisplayAlert("", "Turn on camera permissions in the Settings to allow Roadside to use your camera", "Go To Settings", "Cancel");
                    if (result)
                    {
                        DependencyService.Get<IOpenSettings>().Opensettings();
                        return;
                    }
                }
                return;
            }
            await CrossMedia.Current.Initialize();
            if (!CrossMedia.Current.IsCameraAvailable || !CrossMedia.Current.IsTakePhotoSupported)
            {
                ToastHelper.ShowErrorToast("No Camera", ":( No camera available.");
                return;
            }
            var file = await CrossMedia.Current.TakePhotoAsync(new Plugin.Media.Abstractions.StoreCameraMediaOptions
            {
                Directory = "vehicle",
                Name = "vehicle.png"
            });
            if (file == null)
                return;

            ResizeImage(file);

            //IsDefaultImage = false;
            //CustomImage.Source = file.Path;
            //CustomImage.ClassId = null;
        }

        public static BindableProperty ImageHeightProperty =
            BindableProperty.Create<CustomImageUpload, double>(ctrl => ctrl.ImageHeight,
                defaultValue: 150,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (CustomImageUpload)bindable;
                    ctrl.ImageHeight = newValue;
                });

        public double ImageHeight
        {
            get { return (double)GetValue(ImageHeightProperty); }
            set
            {
                SetValue(ImageHeightProperty, value);
                if (ImageLayout != null)
                    ImageLayout.HeightRequest = value;
                if (CustomImage != null)
                    CustomImage.HeightRequest = value;
            }
        }

        public static BindableProperty ImageWidthProperty =
            BindableProperty.Create<CustomImageUpload, double>(ctrl => ctrl.ImageWidth,
                defaultValue: 150,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (CustomImageUpload)bindable;
                    ctrl.ImageWidth = newValue;
                });

        public double ImageWidth
        {
            get { return (double)GetValue(ImageWidthProperty); }
            set
            {
                SetValue(ImageWidthProperty, value);
                if (ImageLayout != null)
                    ImageLayout.WidthRequest = value;
                if (CustomImage != null)
                    CustomImage.WidthRequest = value;
            }
        }

        public static BindableProperty CurrentPageProperty =
           BindableProperty.Create<CustomImageUpload, Page>(ctrl => ctrl.CurrentPage,
               defaultValue: null,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) =>
               {
                   var ctrl = (CustomImageUpload)bindable;
                   ctrl.CurrentPage = newValue;
               });

        public Page CurrentPage
        {
            get { return (Page)GetValue(CurrentPageProperty); }
            set
            {
                SetValue(CurrentPageProperty, value);
            }
        }

        public static BindableProperty IsBottomButtonsVisibleProperty =
           BindableProperty.Create<CustomImageUpload, bool>(ctrl => ctrl.IsBottomButtonsVisible,
               defaultValue: true,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) =>
               {
                   var ctrl = (CustomImageUpload)bindable;
                   ctrl.IsBottomButtonsVisible = newValue;
               });

        public bool IsBottomButtonsVisible
        {
            get { return (bool)GetValue(IsBottomButtonsVisibleProperty); }
            set
            {
                SetValue(IsBottomButtonsVisibleProperty, value);
                //AddOrRemoveButtons(value);
            }
        }

        public static BindableProperty DefaultImageSourceProperty =
           BindableProperty.Create<CustomImageUpload, string>(ctrl => ctrl.DefaultImageSource,
               defaultValue: "NoImage",
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) =>
               {
                   var ctrl = (CustomImageUpload)bindable;
                   ctrl.DefaultImageSource = newValue;
               });

        public string DefaultImageSource
        {
            get { return (string)GetValue(DefaultImageSourceProperty); }
            set
            {
                SetValue(DefaultImageSourceProperty, value);
                CustomImage.Source = value;
            }
        }

        /// <summary>
        /// Resizes the image.
        /// </summary>
        /// <param name="file">The file.</param>
        /// <returns></returns>
        private async Task ResizeImage(Plugin.Media.Abstractions.MediaFile file)
        {
            if (Device.OS == TargetPlatform.Android)
            {
                await Navigation.PushModalAsync(new CropView(file.Path, Refresh));
            }
            else if (Device.OS == TargetPlatform.iOS)
            {
                //TODO: once image cropping issue fix in iOS we need to uncomment this lines
                var memoryStream = new MemoryStream();
                await file.GetStream().CopyToAsync(memoryStream);
                byte[] imageAsByte = memoryStream.ToArray();

                await Navigation.PushModalAsync(new CropView(imageAsByte, Refresh));

                //TODO: Remove these lines once image cropping issue fix
                //IsDefaultImage = false;
                //CustomImage.Source = file.Path;
                //CustomImage.ClassId = null;
            }
        }

        /// <summary>
        /// Refresh listener for Image Resize
        /// </summary>
        private void Refresh()
        {
            try
            {
                if (Global.CroppedImage != null)
                {
                    Stream stream = new MemoryStream(Global.CroppedImage);
                    IsDefaultImage = false;
                    CustomImage.Source = Xamarin.Forms.ImageSource.FromStream(() => stream);
                    CustomImage.ClassId = null;

                    //making null immediately after setting image to source
                    Global.CroppedImage = null;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.Message);
            }
        }
    }
}
