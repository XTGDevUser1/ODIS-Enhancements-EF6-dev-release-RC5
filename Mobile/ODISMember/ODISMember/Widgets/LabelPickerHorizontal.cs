using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using ODISMember.Classes;
using FFImageLoading.Forms;
using ODISMember.CustomControls;

namespace ODISMember.Widgets
{
	public partial class LabelPickerHorizontal : StackLayout
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
		public LabelPickerHorizontal ()
		{
			this.Orientation = StackOrientation.Vertical;
			this.Spacing = 0;

			LabelTitle = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
				//HorizontalOptions = LayoutOptions.CenterAndExpand
				HorizontalTextAlignment = TextAlignment.Start
			};
			LabelError = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
				HorizontalTextAlignment = TextAlignment.Start,
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

            StackLayout stack = new StackLayout () {
				Orientation = StackOrientation.Horizontal
			};


			stack.Children.Add (Picker);
			stack.Children.Add (ImageValidate);

			Grid grid = new Grid
			{
				HorizontalOptions = LayoutOptions.FillAndExpand,
				RowDefinitions = 
				{
					new RowDefinition { Height = GridLength.Auto },
					new RowDefinition { Height = GridLength.Auto }

				},
				ColumnDefinitions = 
				{
					new ColumnDefinition  { Width = new GridLength(1, GridUnitType.Star) },
					new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
				}
				};

			grid.Children.Add(LabelTitle, 0, 0);
			grid.Children.Add(stack, 1, 0);
			grid.Children.Add (LabelError,1,1);
			this.Children.Add (grid);
		}public bool onValidate(){
			Validate.Invoke (new object (), EventArgs.Empty);
			return IsValid;
		}
        public string GetSelectedValue()
        {
            int index = Picker.SelectedIndex;
            if ((!string.IsNullOrEmpty(PickerHint) && index == 0) || index<0)
            {
                return string.Empty;
            }
            else
            {
                return Picker.Items[index];
            }
        }
        public static BindableProperty PickerHintProperty =
            BindableProperty.Create<LabelPickerHorizontal, string>(ctrl => ctrl.PickerHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelPickerHorizontal)bindable;
                    ctrl.PickerHint = newValue;
                });

        public string PickerHint
        {
            get { return (string)GetValue(PickerHintProperty); }
            set
            {
                SetValue(PickerHintProperty, value);
                if (!string.IsNullOrEmpty(value))
                {
                    Picker.Items.Add(value);
                    Picker.SelectedIndex = 0;
                }
            }
        }
        public static BindableProperty LabelTextProperty = 
			BindableProperty.Create<LabelPickerHorizontal, string>(ctrl => ctrl.LabelText,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerHorizontal)bindable;
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
			BindableProperty.Create<LabelPickerHorizontal, bool>(ctrl => ctrl.IsValid,
				defaultValue: true,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerHorizontal)bindable;
					ctrl.IsValid = newValue;
				});

		public bool IsValid {
			get { return (bool)GetValue(IsValidProperty); }
			set { 
				SetValue (IsValidProperty, value);
			}
		}

		public static BindableProperty EntryErrorMessageProperty = 
			BindableProperty.Create<LabelPickerHorizontal, string>(ctrl => ctrl.EntryErrorMessage,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelPickerHorizontal)bindable;
					ctrl.EntryErrorMessage = newValue;
				});

		public string EntryErrorMessage {
			get { return (string)GetValue(EntryErrorMessageProperty); }
			set { 
				SetValue (EntryErrorMessageProperty, value);
				LabelError.Text= value;
			}
		}

        public static BindableProperty PickerTextAlignmentProperty =
            BindableProperty.Create<LabelPickerHorizontal, TextAlignment>(ctrl => ctrl.PickerTextAlignment,
                defaultValue: TextAlignment.Start,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelPickerHorizontal)bindable;
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

    }
}

