using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Classes;
using ODISMember.CustomControls;

namespace ODISMember.CustomControls
{
	public class CustomDatePicker : StackLayout
	{
		public CustomImageButton DateButton;
		public DateEntry DateEntry;
		private DateTime? _OldDate;
		private DatePicker _Picker;
		//private IViewContainer<View> _ParentLayout;

		public static readonly BindableProperty DateProperty =
			BindableProperty.Create<CustomDatePicker, DateTime?>(p => p.Date, null);
		public DateTime? Date
		{
			get { return (DateTime?)GetValue(DateProperty); }
			set { SetValue(DateProperty, value); }
		}

		public static readonly BindableProperty TextProperty = BindableProperty.Create<CustomDatePicker, string>(p => p.Text, null);
		public string Text
		{
			get { return (string)GetValue(TextProperty); }
			private set { 
				SetValue(TextProperty, value); 

				DateEntry.Text = value;
			}
		}

		public static readonly BindableProperty DefaultTextProperty = BindableProperty.Create<CustomDatePicker, string>(p => p.DefaultText, null);
		public string DefaultText
		{
			get { return (string)GetValue(DefaultTextProperty); }
			set { SetValue(DefaultTextProperty, value); }
		}

		public static readonly BindableProperty FormatProperty =
			BindableProperty.Create<CustomDatePicker, string>(p => p.Format, "MM'/'dd'/'yyyy");
		public string Format
		{
			get { return (string)GetValue(FormatProperty); }
			set { SetValue(FormatProperty, value); }
		}

		//hide the command so you don't accidentally override it
		/*new public Command Command
		{
			get { return (Command)GetValue(DateButton.CommandProperty); }
			private set { SetValue(DateButton.CommandProperty, value); }
		}*/

		public event EventHandler<DateChangedEventArgs> DateSelected;

		public CustomDatePicker ()
		{
            this.HorizontalOptions = LayoutOptions.FillAndExpand;
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
                    new ColumnDefinition { Width = new GridLength(20) }
                }
            };
            DateButton = new CustomImageButton (){
				ImageUrl = ImagePathResources.DatePickerIcon,
				HeightRequest = 30,
				WidthRequest = 30,
				HorizontalOptions = LayoutOptions.End

			};
            
            DateEntry = new DateEntry (){
				Font = FontResources.EntryLabelEntryFont,
				HorizontalOptions =LayoutOptions.FillAndExpand,
				HasBorder = true,
				XAlign = TextAlignment.Center,
				TextColor = ColorResources.EntryLabelValueColor
			};


			this.Orientation = StackOrientation.Horizontal;
		
			_Picker = new DatePicker
			{
				IsVisible = false
			};

			//handle the focus/unfocus or rather the showing and hiding of the dateipicker
			_Picker.Focused += _Picker_Focused;
			_Picker.Unfocused += _Picker_Unfocused;

			DateButton.ImageClick += (object sender, EventArgs e) => {
                if(_Picker.IsFocused)
                {
                    _Picker.Unfocus();
                }
				_Picker.Focus();
			};

            
			_UpdateText();

            grid.Children.Add(DateEntry, 0, 0);
            grid.Children.Add(DateButton, 1, 0);

            this.Children.Add(grid);

            //this.Children.Add (DateEntry);
			//this.Children.Add (DateButton);
			this.Children.Add(_Picker);
		}
		public string GetSelectedDate(){
			if (!string.IsNullOrEmpty (DateEntry.Text)) {
				return DateEntry.Text;
			} else {
				return null;
			}
		}

		/*private IViewContainer<View> _GetParentLayout(VisualElement ParentView)
		{
			//StackLayout, RelativeLayout, Grid, and AbsoluteLayout all implement IViewContainer,
			//it would be very rare that this method would return null.
			IViewContainer<View> parent = ParentView as IViewContainer<View>;
			if (ParentView == null)
			{
				return null;
			}
			else if (parent != null)
			{
				return parent;
			}
			else
			{
				return _GetParentLayout(ParentView.ParentView);
			}
		}*/

		void _Picker_Focused(object sender, FocusEventArgs e)
		{
			//default the date to now if Date is empty
			_Picker.Date = Date ?? DateTime.Now;
		}

		void _Picker_Unfocused(object sender, FocusEventArgs e)
		{
			//this always sets.. can't cancel the dialog.
			Date = _Picker.Date;
			_UpdateText();
		}

		protected override void OnBindingContextChanged()
		{
			base.OnBindingContextChanged();
			_UpdateText();
		}

		private void _UpdateText()
		{
			//the button has a default text, use that the first time.
			if (Date != null)
			{
				//default formatting is in the FormatProperty BindableProperty 
				DateEntry.Text = Date.Value.ToString(Format);
			}
			else
			{
				DateEntry.Text = DefaultText;
			}
		}
		protected override void OnPropertyChanging(string propertyName = null)
		{
			//set this so there is an old date for the DateChangedEventArgs
			base.OnPropertyChanging(propertyName);
			_OldDate = Date;
		}

		protected override void OnPropertyChanged(string propertyName = null)
		{
			base.OnPropertyChanged(propertyName);
			if (propertyName == DateProperty.PropertyName)
			{
				//if the event isn't null, and the old date isn't null, and the date isn't null ... EVENT!
				if (DateSelected != null && _OldDate != null && Date != null)
				{
					DateSelected(this, new DateChangedEventArgs((DateTime)_OldDate, (DateTime)Date));
				}
				//if the event isn't null, and the date isn't null ... EVENT!
				else if (DateSelected != null && Date != null)
				{
					DateSelected(this, new DateChangedEventArgs((DateTime)Date, (DateTime)Date));
				}
				_OldDate = null;
			}
		}
	}
}

