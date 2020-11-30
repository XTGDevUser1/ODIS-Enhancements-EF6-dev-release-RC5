using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using System;
using System.Collections.Generic;
using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class Benefits : ContentView, ITabView
    {
        BaseContentPage Parent;
        LoggerHelper logger = new LoggerHelper();
        public Benefits(BaseContentPage parent)
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.BENEFITS);

            Parent = parent;
            string phoneNumber = String.Format("{0:(###) ###-####}", double.Parse(Constants.MEMBER_SERVICE_PHONE_NUMBER));

            lblThankyou.Text = string.Format("Thank you for choosing the {0} Plan.", Constants.MEMBER_PLAN_NAME);
            lblMemberPlan.Text = string.Format("Please take the time to review this benefit guide – your membership kit - to familiarize yourself with everything the {0} Plan has to offer.", Constants.MEMBER_PLAN_NAME);
            lblMemberServicesNumber.Text = string.Format("We want to help you get the most from your membership, so if you still have questions after reading this guide, please contact Member Services toll-free at {0}.", phoneNumber);
            btnBenefitGuide.Clicked += BtnBenefitGuide_Clicked;
            if (!string.IsNullOrEmpty(Constants.PRODUCT_IMAGE))
            {
                productImage.Source = string.Format("{0}{1}", Global.ApplicationSettings[ApplicationSettings.PRODUCT_IMAGE_VIRTUAL_DIRECTORY_PATH], Constants.PRODUCT_IMAGE);
            }
        }

        private void BtnBenefitGuide_Clicked(object sender, EventArgs e)
        {
            if (Global.ApplicationSettings != null && Global.ApplicationSettings.Count > 0)
            {
                string benefitGuideUrl = string.Format("{0}{1}", Global.ApplicationSettings[ApplicationSettings.BENEFIT_GUIDE_VIRTUAL_DIRECTORY_PATH], Constants.BENEFIT_GUIDE_PDF);
                Device.OpenUri(new Uri(benefitGuideUrl));
            }
            // Navigation.PushAsync(new BenefitGuidePdfViewer());
        }

        public string Title
        {
            get
            {
                return "Benefits";
            }
        }

        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
    }
}

