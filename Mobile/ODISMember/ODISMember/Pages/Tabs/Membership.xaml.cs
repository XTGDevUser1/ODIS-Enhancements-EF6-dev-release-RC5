using System;
using System.Collections.Generic;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.CustomControls;
using ODISMember.Common;
using System.Linq;
using ODISMember.Model;
using ODISMember.Behaviors;
using ODISMember.Entities.Model;


namespace ODISMember
{
	public partial class Membership : ContentPage
	{
		public Membership ()
		{
			InitializeComponent ();
			NavigationPage.SetHasNavigationBar (this, false);
			foreach (string str in ConstantData.MemberPlans.Values.ToList()) {
				widgetPlan.Picker.Items.Add (str);
			}
			foreach (string str in ConstantData.Suffix.Values.ToList()) {
				widgetSuffix.Picker.Items.Add (str);
			}
			foreach (string str in ConstantData.StateProvince.Values.ToList()) {
				widgetStateProvince.Picker.Items.Add (str);
			}
			foreach (string str in ConstantData.CountryProvince.Values.ToList()) {
				widgetCountryCode.Picker.Items.Add (str);
			}
			foreach (string str in ConstantData.CreditCardType.Values.ToList()) {
				widgetCreditCardType.Picker.Items.Add (str);
			}

			widgetExpiration.EntryValue.TextChanged += WidgetExpiration_EntryValue_TextChanged;

		
			btnSubmit.Clicked += BtnSubmit_Clicked;

			widgetPlan.Behaviors.Add (new PickerBehavior (){ IsRequired = true });

			widgetFirstName.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetLastName.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetAddress1.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());

			widgetCity.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetStateProvince.Behaviors.Add (new PickerBehavior (){ IsRequired = true });

			widgetPostalCode.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetPostalCode.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetCountryCode.Behaviors.Add (new PickerBehavior (){ IsRequired = true });
			widgetHomePhone.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetHomePhone.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetCellPhone.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetEmail.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetEmail.Behaviors.Add (new EmailValidatorBehavior ());

			widgetAnnualDueAmount.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetAnnualDueAmount.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetPromotionalCode.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());

			widgetPaymentAmount.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetPaymentAmount.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetCreditCardType.Behaviors.Add (new PickerBehavior (){ IsRequired = true });
			widgetCardholderName.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());

			widgetCardNumber.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetCardNumber.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetExpiration.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());

			widgetCardCode.Behaviors.Add (new RequireValidatorBehavior_LabelEntryVertical ());
			widgetCardCode.Behaviors.Add (new NumberValidatorBehavior_LabelEntryVertical());

			widgetBirthDate.Behaviors.Add (new RequireValidatorBehavior_LabelDateVertical ());
			
			var tapGestureRecognizer = new TapGestureRecognizer ();
			tapGestureRecognizer.Tapped += WidgetActionBar_BtnImage_Clicked;
			tapGestureRecognizer.NumberOfTapsRequired = 1;
			widgetActionBar.BtnImage.GestureRecognizers.Add (tapGestureRecognizer);

			Global.AddPage (this);
		}

		void WidgetActionBar_BtnImage_Clicked (object sender, EventArgs e)
		{
			Global.RemovePage (this);
			Navigation.PopAsync ();
		}

		void WidgetExpiration_EntryValue_TextChanged (object sender, TextChangedEventArgs e)
		{
			if (!string.IsNullOrEmpty (e.OldTextValue) && !string.IsNullOrEmpty (e.NewTextValue) && e.OldTextValue.Length == 1 && e.NewTextValue.Length == 2) {
				widgetExpiration.EntryValue.Text = e.NewTextValue + "/";
			}
		}

		void BtnSubmit_Clicked (object sender, EventArgs e)
		{
			widgetPlan.onValidate ();
			widgetFirstName.onValidate ();
			widgetLastName.onValidate ();
			widgetAddress1.onValidate ();
			widgetCity.onValidate ();
			widgetStateProvince.onValidate ();
			widgetPostalCode.onValidate ();
			widgetCountryCode.onValidate ();
			widgetHomePhone.onValidate ();
			widgetEmail.onValidate ();
			widgetAnnualDueAmount.onValidate ();
			widgetPromotionalCode.onValidate ();
			widgetPaymentAmount.onValidate ();
			widgetCreditCardType.onValidate ();
			widgetCardholderName.onValidate ();
			widgetCardNumber.onValidate ();
			widgetExpiration.onValidate ();
			widgetCardCode.onValidate ();
			widgetBirthDate.onValidate ();

			if (widgetPlan.IsValid && widgetFirstName.IsValid && widgetLastName.IsValid && widgetAddress1.IsValid &&
			    widgetCity.IsValid && widgetStateProvince.IsValid && widgetPostalCode.IsValid && widgetCountryCode.IsValid &&
			    widgetHomePhone.IsValid && widgetEmail.IsValid && widgetAnnualDueAmount.IsValid && widgetPromotionalCode.IsValid &&
			    widgetPaymentAmount.IsValid && widgetCreditCardType.IsValid && widgetCardholderName.IsValid &&
				widgetCardNumber.IsValid && widgetExpiration.IsValid && widgetCardCode.IsValid && widgetBirthDate.IsValid) {
				MemberModel member = new MemberModel ();
				member.Plan = ConstantData.MemberPlans [widgetPlan.Picker.SelectedIndex];
				member.FirstName = widgetFirstName.EntryValue.Text;
				member.LastName = widgetLastName.EntryValue.Text;
				member.Suffix = ConstantData.Suffix [widgetSuffix.Picker.SelectedIndex];
				member.Address1 = widgetAddress1.EntryValue.Text;
				member.City = widgetCity.EntryValue.Text;
				member.StateProvince = ConstantData.StateProvince [widgetStateProvince.Picker.SelectedIndex];
				member.PostalCode = widgetPostalCode.EntryValue.Text;
				member.CountryCode = ConstantData.CountryProvince [widgetCountryCode.Picker.SelectedIndex];
				member.HomePhoneNumber = long.Parse (widgetHomePhone.EntryValue.Text);
				member.CellPhoneNumber = string.IsNullOrEmpty (widgetCellPhone.EntryValue.Text) ? 0 : long.Parse (widgetCellPhone.EntryValue.Text);
				member.Email = widgetEmail.EntryValue.Text;
				member.AnnualDuesAmount = double.Parse (widgetAnnualDueAmount.EntryValue.Text);
				member.PromotionalCode = widgetPromotionalCode.EntryValue.Text;
				member.PaymentAmount = double.Parse (widgetPaymentAmount.EntryValue.Text);
				member.CreditCardType = ConstantData.CreditCardType [widgetCreditCardType.Picker.SelectedIndex];
				member.CreditCardHolderName = widgetCardholderName.EntryValue.Text;
				member.CreditCardNumber = widgetCardNumber.EntryValue.Text;
				member.CreditCardExpirationDate = widgetExpiration.EntryValue.Text;
				member.CreditCardSecurityCode = widgetCardCode.EntryValue.Text;
				this.Navigation.PushAsync (new MembershipReviewOrder (member));
			}
		}


	}
}

