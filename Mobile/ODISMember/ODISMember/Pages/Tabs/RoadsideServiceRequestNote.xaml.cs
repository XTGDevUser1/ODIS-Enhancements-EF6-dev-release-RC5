using ODISMember.Classes;
using ODISMember.CustomControls;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideServiceRequestNote : CustomContentPage
    {
        public event EventHandler UpdateNote;
        string placeHolderText = string.Empty;
        public RoadsideServiceRequestNote(string note = null)
        {
            InitializeComponent();
            string title = "Note";
            placeHolderText = "Please provide us with any other information you think would be helpful.  This might be information about your location, vehicle, service needed, destination or anything else you feel is important.";
            lblNote.HeightRequest = App.ScreenHeight;
            if (Device.OS == TargetPlatform.Android)
            {
                NavigationPage.SetHasNavigationBar(this, false);
                CustomActionBar customActionBar = new CustomActionBar("Note");
                stackCustomActionBar.Children.Add(customActionBar);
                customActionBar.OnCloseClick += CustomActionBar_OnCloseClick;
                customActionBar.OnDoneClick += CustomActionBar_OnDoneClick;
            }
            else if (Device.OS == TargetPlatform.iOS)
            {
                stackActionBar.HeightRequest = 0;
                Title = title;

                Menu menuDone = new Menu();
                menuDone.Priority = 0;
                menuDone.Name = "Done";
                menuDone.ActionOnClick += SaveNote;
                CommonMenu.CreateMenu(this, menuDone);

                Menu menuCancel = new Menu();
                menuCancel.Priority = 1;
                menuCancel.Name = "Cancel";
                menuCancel.ActionOnClick += closeCurrentPage;
                CommonMenu.CreateMenu(this, menuCancel);
            }
            Device.BeginInvokeOnMainThread(() =>
            {
                if (!string.IsNullOrEmpty(note))
                {
                    lblNote.Text = note;
                }
                else
                {
                    lblNote.Text = placeHolderText;
                    lblNote.TextColor = Color.Gray;
                }

                lblNote.BackgroundColor = Color.White;
                //lblNote.TextChanged += LblNote_TextChanged;
            });
        }

        private void LblNote_Focused(object sender, FocusEventArgs e)
        {
            if (lblNote.Text.Equals(placeHolderText))
            {
                lblNote.Text = "";
                lblNote.TextColor = Color.Black;
                //lblNote.HeightRequest = 115;
            }
            scrollNote.ScrollToAsync(0, 0, false);
        }

        private void LblNote_Unfocused(object sender, FocusEventArgs e)
        {
            if (lblNote.Text.Equals("")) 
            {
                lblNote.Text = placeHolderText;
                lblNote.TextColor = Color.Gray;
            }
        }
        private void CustomActionBar_OnDoneClick(object sender, EventArgs e)
        {
            SaveNote();
        }

        private void CustomActionBar_OnCloseClick(object sender, EventArgs e)
        {
            closeCurrentPage();
        }
        private void LblNote_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (UpdateNote != null && lblNote.Text != placeHolderText)
            {
                UpdateNote.Invoke(lblNote.Text, EventArgs.Empty);
            }
        }
        private void closeCurrentPage()
        {
            Navigation.PopAsync();
        }
        private void SaveNote()
        {
            if (UpdateNote != null && lblNote.Text != placeHolderText)
            {
                UpdateNote.Invoke(lblNote.Text, EventArgs.Empty);
            }
            Navigation.PopAsync();
        }
        protected override void OnAppearing()
        {
            lblNote.Unfocus();
            base.OnAppearing();
        }
    }
}
