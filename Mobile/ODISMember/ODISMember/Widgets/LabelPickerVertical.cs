using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using FFImageLoading.Forms;
using ODISMember.CustomControls;
using ODISMember.Classes;
using System.Linq;
namespace ODISMember.Widgets
{
	public partial class LabelPickerVertical : StackLayout
	{
		public CustomPicker Picker {
			get;
			set;
		}
		public ExtendedLabel LabelTitle {
			get;
			set;
		}
		public ExtendedLabel LabelError {
			get;
			set;
		}
		public CachedImage ImageValidate {
			get;
			set;
		}
		public EventHandler Validate {
			get;
			set;
		}
        public StackLayout stack;

        public LabelPickerVertical ()
		{
			this.Orientation = StackOrientation.Vertical;
			this.Spacing = 0;

			LabelTitle = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand
			};
			LabelError = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
				TextColor = Color.Red
			};
			Picker = new CustomPicker(){ 
				HorizontalOptions= LayoutOptions.FillAndExpand,
                PickerTextAlignment = TextAlignment.Start,
                Font = FontResources.EntryLabelFontSize
            };
            
            ImageValidate = new CachedImage()
            {
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
                WidthRequest = 20,
                HeightRequest = 20,
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false

            };
            stack = new StackLayout () {
				Orientation = StackOrientation.Horizontal,
                Padding = new Thickness(20, 0, 0, 0)
            };


			stack.Children.Add (Picker);
			stack.Children.Add (ImageValidate);
			this.Children.Add (LabelTitle);
			this.Children.Add (stack);
			this.Children.Add (LabelError);
		}
		public bool onValidate(){
			Validate.Invoke (new object (), EventArgs.Empty);
			return IsValid;
		}
		public string GetSelectedValue(){
			int index = Picker.SelectedIndex;
			if (!string.IsNullOrEmpty (PickerHint) && index == 0) {
				return null;
			} else {
				return Picker.Items [index];
			}
		}
		public static BindableProperty LabelTextProperty = 
			BindableProperty.Create<LabelPickerVertical, string>(ctrl => ctrl.LabelText,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.LabelText = newValue;
				});

		public string LabelText {
			get { return (string)GetValue(LabelTextProperty); }
			set { 
				SetValue (LabelTextProperty, value);
				LabelTitle.Text = value;
			}
		}

		public static BindableProperty IsValidProperty = 
			BindableProperty.Create<LabelPickerVertical, bool>(ctrl => ctrl.IsValid,
				defaultValue: true,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.IsValid = newValue;
				});

		public bool IsValid {
			get { return (bool)GetValue(IsValidProperty); }
			set { 
				SetValue (IsValidProperty, value);
			}
		}

		public static BindableProperty EntryErrorMessageProperty = 
			BindableProperty.Create<LabelPickerVertical, string>(ctrl => ctrl.EntryErrorMessage,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.EntryErrorMessage = newValue;
				});

		public string EntryErrorMessage {
			get { return (string)GetValue(EntryErrorMessageProperty); }
			set { 
				SetValue (EntryErrorMessageProperty, value);
				LabelError.Text= value;
			}
		}


		public static BindableProperty IsLabelVisibleProperty = 
			BindableProperty.Create<LabelPickerVertical, bool>(ctrl => ctrl.IsLabelVisible,
				defaultValue: true,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.IsLabelVisible = newValue;
				});

		public bool IsLabelVisible {
			get { return (bool)GetValue(IsLabelVisibleProperty); }
			set { 
				SetValue (IsLabelVisibleProperty, value);
				if (value == false) {
					LabelTitle.HeightRequest = 0;
				}
			}
		}

		public static BindableProperty PickerHintProperty = 
			BindableProperty.Create<LabelPickerVertical, string>(ctrl => ctrl.PickerHint,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.PickerHint = newValue;
				});

		public string PickerHint {
			get { return (string)GetValue(PickerHintProperty); }
			set { 
				SetValue (PickerHintProperty, value);
				if (!string.IsNullOrEmpty (value)) {
					Picker.Items.Add (value);
					Picker.SelectedIndex = 0;
				}
			}
		}

		public static BindableProperty IsLeftAlignProperty = 
			BindableProperty.Create<LabelPickerVertical, bool>(ctrl => ctrl.IsLeftAlign,
				defaultValue: false,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerVertical)bindable;
					ctrl.IsLeftAlign = newValue;
				});

		public bool IsLeftAlign {
			get { return (bool)GetValue(IsLeftAlignProperty); }
			set { 
				SetValue (IsLeftAlignProperty, value);
				if (value == true) {
					this.LabelTitle.HorizontalTextAlignment = TextAlignment.Start;
					this.LabelTitle.HorizontalOptions = LayoutOptions.StartAndExpand;
                    this.stack.Padding = new Thickness(0);

                }
			}
		}


        public static BindableProperty PickerTextAlignmentProperty =
            BindableProperty.Create<LabelPickerVertical, TextAlignment>(ctrl => ctrl.PickerTextAlignment,
                defaultValue: TextAlignment.Start,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelPickerVertical)bindable;
                    ctrl.PickerTextAlignment = newValue;
                });

        public TextAlignment PickerTextAlignment
        {
            get { return (TextAlignment)GetValue(PickerTextAlignmentProperty); }
            set
            {
                SetValue(PickerTextAlignmentProperty, value);
                Picker.PickerTextAlignment = value;
            }
        }

        public static BindableProperty SelectedItemtProperty =
            BindableProperty.Create<LabelPickerVertical, string>(ctrl => ctrl.SelectedItem,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelPickerVertical)bindable;
                    ctrl.SelectedItem = newValue;
                });

        public string SelectedItem
        {
            get { return (string)GetValue(SelectedItemtProperty); }
            set
            {
                SetValue(SelectedItemtProperty, value);
                if (Picker != null && Picker.Items.Count > 0)
                {
                    if(Picker.Items.Contains(value))
                    Picker.SelectedIndex = Picker.Items.IndexOf(value);
                }
            }
        }

    }
}

