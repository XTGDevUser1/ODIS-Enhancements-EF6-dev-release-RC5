using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Behaviors;
using ODISMember.Classes;

namespace ODISMember.Widgets
{
	public partial class LabelValueHorizontal : StackLayout
	{
		public ExtendedLabel LabelValue {
			get;
			set;
		}
		public ExtendedLabel LabelTitle {
			get;
			set;
		}

		public LabelValueHorizontal ()
		{
            this.Spacing = 0;
            Padding = new Thickness(10, 5, 10, 23);

			LabelTitle = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["LabelValueLabelStyle"],
				HorizontalTextAlignment = TextAlignment.Start
			};
			LabelValue = new ExtendedLabel (){
				Style = (Style)Application.Current.Resources["LabelValueValueStyle"],
				HorizontalTextAlignment = TextAlignment.Start
			};

			Grid grid = new Grid
			{
				HorizontalOptions = LayoutOptions.FillAndExpand,
				RowDefinitions = 
				{
					new RowDefinition { Height = GridLength.Auto }

				},
				ColumnDefinitions = 
				{
					new ColumnDefinition  { Width = new GridLength(1, GridUnitType.Star) },
					new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
				}
				};

			grid.Children.Add(LabelTitle, 0, 0);
			grid.Children.Add(LabelValue, 1, 0);
			
			this.Children.Add (grid);
		}

		public static BindableProperty LabelTextProperty = 
			BindableProperty.Create<LabelValueHorizontal, string>(ctrl => ctrl.LabelText,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelValueHorizontal)bindable;
					ctrl.LabelText = newValue;
				});

		public string LabelText {
			get { return (string)GetValue(LabelTextProperty); }
			set { 
				SetValue (LabelTextProperty, value);
				LabelTitle.Text = value;
			}
		}


		public static BindableProperty ValueTextProperty = 
			BindableProperty.Create<LabelValueHorizontal, string>(ctrl => ctrl.LabelText,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (LabelValueHorizontal)bindable;
					ctrl.ValueText = newValue;
				});

		public string ValueText {
			get { return (string)GetValue(ValueTextProperty); }
			set { 
				SetValue (ValueTextProperty, value);
				LabelValue.Text = value;
			}
		}

	}
}

