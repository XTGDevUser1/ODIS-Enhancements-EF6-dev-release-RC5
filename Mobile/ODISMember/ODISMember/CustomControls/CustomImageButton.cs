using System;
using Xamarin.Forms;
using FFImageLoading.Forms;

namespace ODISMember.CustomControls
{
	public class CustomImageButton : StackLayout
	{
		public Button CustomButton {
			get;
			set;
		}

		public CachedImage CustomImage {
			get;
			set;
		}
		public event EventHandler ImageClick;


		public static BindableProperty ImageUrlProperty = 
			BindableProperty.Create<CustomImageButton, string> (ctrl => ctrl.ImageUrl,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (CustomImageButton)bindable;
					ctrl.ImageUrl = newValue;
				});

		public string ImageUrl {
			get { return (string)GetValue (ImageUrlProperty); }
			set { 
				SetValue (ImageUrlProperty, value);
				CustomImage.Source = value;
			}
		}

		public CustomImageButton ()
		{
			RelativeLayout relativeLayout = new RelativeLayout ();
			CustomButton = new Button (){
				BackgroundColor = Color.Transparent
			};
			CustomImage = new CachedImage (){
				//Aspect=Aspect.AspectFit,
				CacheDuration = TimeSpan.FromDays(30),
				DownsampleToViewSize = true,
				RetryCount = 0,
				RetryDelay = 250,
				TransparencyEnabled = false
			};

			CustomButton.Clicked += (object sender, EventArgs e) => {
                if (this.ImageClick != null)
                {
                    this.ImageClick.Invoke(this, e);
                }
			}; 

	
			relativeLayout.Children.Add (CustomImage, 
				Constraint.Constant (0), 
				Constraint.Constant (0),
				Constraint.RelativeToParent ((parent) => {
					return ((parent.WidthRequest == -1) ? parent.Width: parent.WidthRequest);
				}),
				Constraint.RelativeToParent ((parent) => {
					return ((parent.HeightRequest == -1) ? parent.Height: parent.HeightRequest);
				}));
			relativeLayout.Children.Add (CustomButton, 
				Constraint.RelativeToView (CustomImage, (parent, view) => {
					return view.X;
				}), 
				Constraint.RelativeToView (CustomImage, (parent, view) => {
					return view.Y;
				}),
				Constraint.RelativeToView (CustomImage, (parent, view) => {
					return ((view.WidthRequest == -1) ? view.Width: view.WidthRequest);
				}),
				Constraint.RelativeToView (CustomImage, (parent, view) => {
					return ((view.HeightRequest == -1) ? view.Height: view.HeightRequest);
				}));
			this.Children.Add (relativeLayout);
		}

	}
}

