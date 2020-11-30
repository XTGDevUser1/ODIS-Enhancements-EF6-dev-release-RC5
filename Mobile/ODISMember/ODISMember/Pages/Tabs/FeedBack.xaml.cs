using ODISMember.Behaviors;
using ODISMember.Classes;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class FeedBack : ContentPage
    {
        string CommentsPlaceHolderText = string.Empty;
        public FeedBack(byte[] ScreenShootImage)
        {
            InitializeComponent();
            this.Title = "FeedBack";
            CommentsPlaceHolderText = "Comments";
            EditorComments.Text = CommentsPlaceHolderText;
            ImgScreenShoot.Source = null;
            EditorComments.TextColor = Color.Gray;
            if(Device.OS==TargetPlatform.iOS)
            {
                mainStackEditorComments.BackgroundColor = Color.Gray;
            }
            lblCommentsRequirdText.Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"];
            lblCommentsRequirdText.HorizontalOptions = LayoutOptions.CenterAndExpand;
            lblCommentsRequirdText.TextColor = ColorResources.LabelErrorTextColor;
            
            AddSendMenu();
            if (ScreenShootImage != null && ScreenShootImage.Count() > 0)
            {
                ImgScreenShoot.Source = ImageSource.FromStream(() => new MemoryStream(ScreenShootImage));
            }
            EditorComments.Focused += EditorComments_Focused;
            EditorComments.Unfocused += EditorComments_Unfocused;
            //EditorComments.FontFamily = "fsd";
            widgetName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
        }

        private void AddSendMenu()
        {
            Menu menu = new Menu();
            menu.Priority = 0;
            menu.Name = "Send";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += ClickSend; 
            CommonMenu.CreateMenu(this, menu);
        }
        protected override void OnDisappearing()
        {
            Global.IsFeedBackPageActive = false;
            base.OnDisappearing();
        }

        private void ClickSend()
        {
            widgetName.onValidate();
            if(EditorComments.Text==""||EditorComments.Text==CommentsPlaceHolderText)
            {
                lblCommentsRequirdText.Text = "*This field is required";
            }
            else
            {
                lblCommentsRequirdText.IsVisible = false;
            }
            if(widgetName.IsValid)
            {
                ToastHelper.ShowSuccessToast("Thank you", "This feature is under testing");
                Navigation.PopAsync();
            }
        }

        private void EditorComments_Unfocused(object sender, FocusEventArgs e)
        {
            if(EditorComments.Text.Equals(""))
            {
                EditorComments.Text = CommentsPlaceHolderText;
                EditorComments.TextColor = Color.Gray;
            }
        }

        private void EditorComments_Focused(object sender, FocusEventArgs e)
        {
            if(EditorComments.Text.Equals(CommentsPlaceHolderText))
            {
                EditorComments.Text = "";
                EditorComments.TextColor = Color.Black;
            }
        }
    }
}
