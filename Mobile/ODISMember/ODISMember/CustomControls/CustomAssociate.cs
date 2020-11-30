using System;
using Xamarin.Forms;
using ODISMember.Widgets;
using ODISMember.Entities;
using ODISMember.CustomControls;
using ODISMember.Classes;
using ODISMember.Behaviors;

namespace ODISMember
{
	public class CustomAssociate : StackLayout
	{
		public LabelEntryVertical FirstName {
			get;
			set;
		}
		public LabelEntryVertical LastName {
			get;
			set;
		}
		public LabelDateVertical DateOfBirth {
			get;
			set;
		}
        public CustomImageButton BtnRemove{ get; set; }
        public CustomAssociate (Associate associate)
		{
			this.BindingContext = associate;
			FirstName = new LabelEntryVertical () {
				EntryHint = "First Name",
				IsLabelVisible = false,
				IsLeftAlign = true
			};
            FirstName.SetBinding (LabelEntryVertical.EntryTextProperty, "FirstName");
            FirstName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            LastName = new LabelEntryVertical () {
				EntryHint = "Last Name",
				IsLabelVisible = false,
				IsLeftAlign = true
			};
            LastName.SetBinding (LabelEntryVertical.EntryTextProperty, "LastName");
            LastName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            DateOfBirth = new LabelDateVertical (){ 
				DateEntryHint="Date Of Birth",
				IsLabelVisible = false,
				IsLeftAlign = true
			};
			DateOfBirth.SetBinding (LabelDateVertical.DateProperty, "DateOfBirth");
            DateOfBirth.Behaviors.Add(new RequireValidatorBehavior_LabelDateVertical());
            Frame frame = new Frame (){ 
				Padding=new Thickness(5),
				OutlineColor = Color.Gray
			};
			StackLayout stack = new StackLayout (){
				Padding = new Thickness(0)
			};
			BtnRemove = new CustomImageButton (){
				ImageUrl = ImagePathResources.RemoveIcon,
                HorizontalOptions = LayoutOptions.End,
                HeightRequest = 50,
                WidthRequest = 50
			};
            stack.Children.Add(BtnRemove);
			stack.Children.Add (FirstName);
			stack.Children.Add (LastName);
			stack.Children.Add (DateOfBirth);
			frame.Content = stack;
			this.Children.Add (frame);
		}

        public bool onValidate() {
          bool isFirstNameValid =  FirstName.onValidate();
          bool isLastNameValid = LastName.onValidate();
          bool isDateOfBirthValid = DateOfBirth.onValidate();
            if (isFirstNameValid && isLastNameValid && isDateOfBirthValid)
            {
                return true;
            }
            else {
                return false;
            }
        }
	}
}

