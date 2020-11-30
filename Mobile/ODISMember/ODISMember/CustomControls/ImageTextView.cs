using FFImageLoading.Forms;
using FFImageLoading.Transformations;
using FFImageLoading.Work;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class ImageTextView : StackLayout
    {
        public CachedImage Image
        {
            get;
            set;
        }
        public Button CustomButton
        {
            get;
            set;
        }
        public ExtendedLabel Title
        {
            get;
            set;
        }
        public event EventHandler ImageClick;
        public ImageTextView()
        {

            RelativeLayout relativeLayout = new RelativeLayout();
            StackLayout stackContent = new StackLayout();
            CustomButton = new Button()
            {
                BackgroundColor = Color.Transparent
            };
            Image = new CachedImage()
            {
                Aspect = Aspect.Fill,
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false,
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                Transformations = new System.Collections.Generic.List<ITransformation>() {
                    new CircleTransformation()
                }
            };
            Title = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                FontSize = 18
            };
            CustomButton.Clicked += (object sender, EventArgs e) =>
            {
                if (this.ImageClick != null)
                {
                    this.ImageClick.Invoke(this, e);
                }
            };
            stackContent.Children.Add(Image);
            stackContent.Children.Add(Title);

            relativeLayout.Children.Add(stackContent,
                Constraint.RelativeToParent((parent) =>
                {
                    return parent.X;
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return parent.Y;
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
                }));
            relativeLayout.Children.Add(CustomButton,
                Constraint.RelativeToView(stackContent, (parent, view) =>
                {
                    return view.X;
                }),
                Constraint.RelativeToView(stackContent, (parent, view) =>
                {
                    return view.Y;
                }),
                Constraint.RelativeToView(stackContent, (parent, view) =>
                {
                    return ((view.WidthRequest == -1) ? view.Width : view.WidthRequest);
                }),
                Constraint.RelativeToView(stackContent, (parent, view) =>
                {
                    return ((view.HeightRequest == -1) ? view.Height : view.HeightRequest);
                }));
            this.Children.Add(relativeLayout);
        }
        public void SelectImage()
        {
            if (this.Image != null)
            {
                this.Image.Source = this.SelectedImageUrl;
            }
        }
        public void UnSelectImage()
        {
            if (this.Image != null)
            {
                this.Image.Source = this.UnSelectedImageUrl;
            }
        }

        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<ImageTextView, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (ImageTextView)bindable;
                    ctrl.LabelText = newValue;
                });

        public string LabelText
        {
            get { return (string)GetValue(LabelTextProperty); }
            set
            {
                SetValue(LabelTextProperty, value);
                if (Title != null)
                {
                    Title.Text = value;
                }
            }
        }
        public static BindableProperty SelectedImageUrlProperty =
            BindableProperty.Create<ImageTextView, string>(ctrl => ctrl.SelectedImageUrl,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (ImageTextView)bindable;
                    ctrl.SelectedImageUrl = newValue;
                });

        public string SelectedImageUrl
        {
            get { return (string)GetValue(SelectedImageUrlProperty); }
            set
            {
                SetValue(SelectedImageUrlProperty, value);
            }
        }

        public static BindableProperty UnSelectedImageUrlProperty =
            BindableProperty.Create<ImageTextView, string>(ctrl => ctrl.UnSelectedImageUrl,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (ImageTextView)bindable;
                    ctrl.UnSelectedImageUrl = newValue;
                });

        public string UnSelectedImageUrl
        {
            get { return (string)GetValue(UnSelectedImageUrlProperty); }
            set
            {
                SetValue(UnSelectedImageUrlProperty, value);
                if (Image != null)
                {
                    Image.Source = value;
                }
            }
        }
    }
}
