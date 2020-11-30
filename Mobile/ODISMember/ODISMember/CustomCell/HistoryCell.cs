using ODISMember.Common;
using ODISMember.CustomControls.CardLayout;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Pages.Tabs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomCell
{
    public class HistoryCell : CustomViewCell
    {
        Grid grid;
        BaseContentPage CurrentBaseContentPage = null;
        public HistoryCell(BaseContentPage currentPage)
        {
            CurrentBaseContentPage = currentPage;
            StackLayout cellMainLayout = new StackLayout()
            {
                Padding = new Thickness(10, 15, 10, 0)
            };

            grid = new Grid
            {
                Padding = new Thickness(0, 1, 1, 1),
                RowSpacing = 1,
                ColumnSpacing = 1,
                BackgroundColor = StyleKit.CardBorderColor,
                VerticalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions = {
                    new RowDefinition{ Height = GridLength.Auto },
                    new RowDefinition { Height = new GridLength (30, GridUnitType.Absolute) }
                },
                ColumnDefinitions = {
                    new ColumnDefinition { Width = new GridLength (4, GridUnitType.Absolute) },
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) }
                }
            };
            cellMainLayout.Children.Add(grid);
            StackLayout cellLayout = new StackLayout()
            {
                Padding = new Thickness(0),
                BackgroundColor = Color.White,
                VerticalOptions = LayoutOptions.FillAndExpand,
                HorizontalOptions= LayoutOptions.FillAndExpand
            };
            cellLayout.Children.Add(cellMainLayout);
            
            View = cellLayout;
        }
        protected override void OnBindingContextChanged()
        {
            MemberHistoryModel history = (MemberHistoryModel)BindingContext;
            if (history != null)
            {
                Card detailCard = new Card()
                {
                    Title = history.ServiceType,
                    Description = history.YearMakeModel,
                    Date = history.CreateDate.Value,
                    PersonName = history.MemberName
                };
                RelativeLayout relativeButtonLayout = new RelativeLayout();
                IconLabelView iconLabelView = new IconLabelView(null, "View Details");

                Button btnViewDetails = new Button()
                {
                    BackgroundColor = Color.Transparent
                };
                btnViewDetails.Clicked += BtnViewDetails_Clicked;
                relativeButtonLayout.Children.Add(iconLabelView,
               Constraint.Constant(0),
               Constraint.Constant(0),
               Constraint.RelativeToParent((parent) =>
               {
                   return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
               }),
               Constraint.RelativeToParent((parent) =>
               {
                   return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
               }));
                relativeButtonLayout.Children.Add(btnViewDetails,
               Constraint.Constant(0),
               Constraint.Constant(0),
               Constraint.RelativeToParent((parent) =>
               {
                   return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
               }),
               Constraint.RelativeToParent((parent) =>
               {
                   return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
               }));

                grid.Children.Add(new CardStatusView(history.StatusID.Value), 0, 1, 0, 2);

                grid.Children.Add(new CardDetailsView(detailCard), 1, 3, 0, 1);

                grid.Children.Add(new IconLabelView(history.StatusID.Value, history.Status), 1, 2, 1, 2); //1, 1);

                grid.Children.Add(relativeButtonLayout, 2, 3, 1, 2);//, 2, 1);

                //grid.Children.Add(new ConfigIconView(), 3, 1);
            }

            base.OnBindingContextChanged();
        }

        private async void BtnViewDetails_Clicked(object sender, EventArgs e)
        {
            Button btnHistory = (Button)sender;
            btnHistory.BackgroundColor = Color.FromHsla(0,0,0,0.5);
            MemberHistoryModel history = (MemberHistoryModel)BindingContext;
            await CurrentBaseContentPage.Navigation.PushAsync(new RoadsideRequestStatus(history.RequestNumber.ToString()));//(history.TrackerID));
            btnHistory.BackgroundColor = Color.Transparent;
        }
    }
}
