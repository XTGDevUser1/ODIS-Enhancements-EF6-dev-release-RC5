using ODISMember.Common;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Classes;
using XLabs.Forms.Controls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using Newtonsoft.Json;
using ODISMember.Helpers.UIHelpers;
using FFImageLoading.Forms;
using ODISMember.Services.Service;
using ODISMember.Shared;
using System.Collections.ObjectModel;

namespace ODISMember.Pages.Tabs
{
    public partial class Home : ContentView, ITabView
    {
        BaseContentPage Parent;
        public string trackingId = string.Empty;
        public LoggerHelper logger = new LoggerHelper();
        MemberHelper memberHelper = new MemberHelper();
        public Home(BaseContentPage parent)
        {
            InitializeComponent();
            //tracking page view
            logger.TrackPageView(PageNames.HOME);
            this.Parent = parent;
            this.BackgroundColor = ColorResources.HomepageBackgroundColor;
            loadMemberActiveCard();
            LoadPosts();
            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
            
        }
        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_ACTIVE_REQUEST || e.EventId == AppConstants.Event.REFRESH_MEMBERSHIP_DETAILS || e.EventId == AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS)
            {
                loadMemberActiveCard();
            }
        }
        public void loadMemberActiveCard()
        {
            memberHelper.GetMemberStatus(Constants.MEMBER_NUMBER)
                .ContinueWith((a) =>
                {
                    if (a.IsCompleted && !a.IsFaulted)
                    {
                        OperationResult operationResult = a.Result;
                        if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                        {
                            Associate currentMember = JsonConvert.DeserializeObject<Associate>(operationResult.Data.ToString());
                            if (!currentMember.IsActive)
                            {
                                Device.BeginInvokeOnMainThread(() =>
                                {
                                    ShowMemberInactive.IsVisible = true;
                                    lblMemberInactiveHeader.Text = " - MEMBER INACTIVE - ";
                                    memberInactiveLayout.Children.Clear();
                                    memberInactiveLayout.Children.Add(GetMemberShipInactiveCard());
                                });
                            }
                            loadActiveRequest(true, currentMember.IsActive);
                        }
                        else
                        {
                            loadActiveRequest(true, true);
                        }
                    }
                });
        }
        public void loadActiveRequest(bool showLoading = true, bool isMemberActive = true)
        {
            if (Global.CurrentMember != null)
            {
                memberHelper.GetActiveRequest(Global.CurrentMember.MembershipNumber).ContinueWith(a =>
            {
                if (a.IsCompleted)
                {
                    var result = a.Result;
                    if (result != null && result.Status == OperationStatus.SUCCESS)
                    {
                        if (result.Data != null)
                        {
                            var serviceRequest = JsonConvert.DeserializeObject<ServiceRequest>(result.Data.ToString());
                            Device.BeginInvokeOnMainThread(() =>
                            {
                                lblServiceRequstsHeader.Text = " - SERVICE REQUESTS - ";
                                mainLayout.Children.Clear();
                                mainLayout.Children.Add(GetActiveRequestCard(serviceRequest));
                            });
                        }
                        else
                        {
                            if (isMemberActive)
                            {
                                Device.BeginInvokeOnMainThread(() =>
                                {
                                    lblServiceRequstsHeader.Text = " - REQUESTS & ALERTS - ";
                                    mainLayout.Children.Clear();
                                    mainLayout.Children.Add(NoRequestsAlertsCard());
                                });
                            }
                        }
                    }
                    else
                    {
                        ToastHelper.ShowErrorToast("Error", result.ErrorMessage);
                    }
                }
            });
            }
        }
        public Grid GetActiveRequestCard(ServiceRequest serviceRequest)
        {
            trackingId = serviceRequest.RequestNumber.ToString();//TrackerID
            Grid parent = new Grid()
            {
                Padding = new Thickness(8, 0, 8, 10),
                RowSpacing = 0
            };
            Grid mainGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.FromHex("#e1e1e3"),
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 162 },
                    new RowDefinition() { Height = 64 }
                }
            };

            Grid imageGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.FromHex("#e4e4e4"),
            };
            CachedImage postImage = new CachedImage()
            {
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false,
                Aspect = Aspect.Fill
            };
            //Image postImage = new Image();
            //postImage.Aspect = Aspect.Fill;
            postImage.Source = Xamarin.Forms.ImageSource.FromStream(() => new System.IO.MemoryStream(Convert.FromBase64String(serviceRequest.MapSnapshot)));


            Grid contentOuterGrid = new Grid()
            {
                BackgroundColor = Color.FromHex("#ffffff"),
                RowSpacing = 0
            };

            Grid contentGrid = new Grid()
            {
                Padding = 15,
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 20 },
                    new RowDefinition() { Height = 4 },
                    new RowDefinition() { Height = 20 }
                }
            };

            ExtendedLabel serviceType = new ExtendedLabel()
            {
                Text = string.Format((serviceRequest.ServiceType).ToUpper() + " SERVICE REQUESTED"),
                Style = (Style)Application.Current.Resources["CardTitleLabelStyle"],
                TextColor = Color.Red
            };
            ExtendedLabel viewStatuslink = new ExtendedLabel()
            {
                Text = "VIEW STATUS",
                Style = (Style)Application.Current.Resources["CardReadLinkStyle"],
                TextColor = Color.FromHex("#017DC7")
            };

            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += (s, e) =>
            {
                Navigation.PushAsync(new RoadsideRequestStatus(trackingId));
            };
            viewStatuslink.GestureRecognizers.Add(tapGestureRecognizer);

            contentGrid.Children.Add(serviceType, 0, 1, 0, 1);
            contentGrid.Children.Add(viewStatuslink, 0, 1, 2, 3);

            contentOuterGrid.Children.Add(contentGrid, 0, 1, 0, 1);

            imageGrid.Children.Add(postImage, 0, 1, 0, 1);

            mainGrid.Children.Add(imageGrid, 0, 1, 0, 1);
            mainGrid.Children.Add(contentOuterGrid, 0, 1, 1, 2);

            parent.Children.Add(mainGrid, 0, 1, 0, 1);
            return parent;
        }

        public Grid GetMemberShipInactiveCard()
        {

            Grid parent = new Grid()
            {
                Padding = new Thickness(8, 0, 8, 10),
                RowSpacing = 0
            };
            Grid mainGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.White,
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 162 },
                    new RowDefinition() { Height = 64 }
                }
            };

            Grid imageGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.FromHex("#ECF0F1")
            };
            ExtendedLabel ExpaireText = new ExtendedLabel()
            {
                Text = "Your membership has expired. Renew today!",
                Style = (Style)Application.Current.Resources["HomePageEmptyRequestCardStyle"],
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalTextAlignment = TextAlignment.Center
            };


            Grid contentOuterGrid = new Grid()
            {
                BackgroundColor = Color.FromHex("#ffffff"),
                RowSpacing = 0
            };

            Grid contentGrid = new Grid()
            {
                Padding = 15,
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 20 },
                    new RowDefinition() { Height = 4 }
                }
            };
            ExtendedLabel viewStatuslink = new ExtendedLabel()
            {
                Text = "Renew Here",
                Style = (Style)Application.Current.Resources["CardReadLinkStyle"],
                TextColor = Color.Green
            };

            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += (s, e) =>
            {
                //Event for click on renew page link
            };
            viewStatuslink.GestureRecognizers.Add(tapGestureRecognizer);

            contentGrid.Children.Add(viewStatuslink, 0, 1, 0, 1);


            contentOuterGrid.Children.Add(contentGrid, 0, 1, 0, 1);

            imageGrid.Children.Add(ExpaireText, 0, 1, 0, 1);

            mainGrid.Children.Add(imageGrid, 0, 1, 0, 1);
            mainGrid.Children.Add(contentOuterGrid, 0, 1, 1, 2);

            parent.Children.Add(mainGrid, 0, 1, 0, 1);
            return parent;
        }

        public Grid NoRequestsAlertsCard()
        {

            Grid parent = new Grid()
            {
                Padding = new Thickness(8, 0, 8, 10),
                RowSpacing = 0
            };
            Grid mainGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.White,
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 162 }
                }
            };

            Grid imageGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.White,
            };
            ExtendedLabel StatusText = new ExtendedLabel()
            {
                Text = "Everything is all good! You don't have any active requests or alerts.",
                Style = (Style)Application.Current.Resources["HomePageEmptyRequestCardStyle"],
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalTextAlignment = TextAlignment.Center
            };
            imageGrid.Children.Add(StatusText, 0, 1, 0, 1);

            mainGrid.Children.Add(imageGrid, 0, 1, 0, 1);
            parent.Children.Add(mainGrid, 0, 1, 0, 1);
            return parent;
        }
        public StackLayout GetRow(string titleText, string subTitleText, string iconUrl = "", string imageUrl = "")
        {
            Image imgIcon = new Image()
            {
                HeightRequest = 50,
                WidthRequest = 50,
                Source = iconUrl
            };

            ExtendedLabel title = new ExtendedLabel()
            {
                Text = titleText,
                Style = (Style)Application.Current.Resources["BaseLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand
            };
            ExtendedLabel subTitle = new ExtendedLabel()
            {
                Text = subTitleText,
                Style = (Style)Application.Current.Resources["BaseLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand
            };

            StackLayout stackTitle = new StackLayout()
            {
                Orientation = StackOrientation.Horizontal,
                Spacing = 20,
                Padding = new Thickness(20, 20, 20, 20),
                BackgroundColor = Color.White

            };
            if (!string.IsNullOrEmpty(iconUrl))
            {
                stackTitle.Children.Add(imgIcon);
            }
            stackTitle.Children.Add(new StackLayout()
            {
                Orientation = StackOrientation.Vertical,
                Spacing = 10,
                //VerticalOptions = LayoutOptions.CenterAndExpand,
                Children = { title, subTitle }
            });
            stackTitle.Children.Add(new Image()
            {
                HorizontalOptions = LayoutOptions.EndAndExpand,
                VerticalOptions = LayoutOptions.StartAndExpand,
                HeightRequest = 20,
                WidthRequest = 20,
                Source = "image.png"
            });

            Image image = new Image()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                Source = imageUrl
            };

            StackLayout rowLayout = new StackLayout()
            {
                Spacing = 20,
                Padding = new Thickness(20, 20, 20, 20),
                BackgroundColor = Color.White
            };
            rowLayout.Children.Add(stackTitle);
            if (!string.IsNullOrEmpty(imageUrl))
            {
                rowLayout.Children.Add(image);
            }

            rowLayout.Children.Add(new BoxView()
            {
                BackgroundColor = Color.Gray,
                HorizontalOptions = LayoutOptions.StartAndExpand,
                HeightRequest = 20,
                WidthRequest = App.ScreenWidth - 125
            });

            rowLayout.Children.Add(new BoxView()
            {
                BackgroundColor = Color.Gray,
                HorizontalOptions = LayoutOptions.StartAndExpand,
                HeightRequest = 20,
                WidthRequest = App.ScreenWidth - 150
            });

            return rowLayout;
        }
        public void LoadPosts()
        {
            memberHelper.GetWordPressPosts().ContinueWith(a =>
            {
                if (a.IsCompleted)
                {
                    var result = a.Result;
                    if (result != null)
                    {
                        foreach (WordPressFeedResult post in result)
                        {
                            Device.BeginInvokeOnMainThread(() =>
                            {
                                wpPosts.Children.Add(RenderPost(post));
                            });
                            //Posts.Add(post);
                        }
                    }
                }
            });
        }
        private Grid RenderPost(WordPressFeedResult post)
        {
            Grid parent = new Grid()
            {
                Padding = new Thickness(8, 0, 8, 10),
                RowSpacing = 0
            };

            Grid mainGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.FromHex("#e1e1e3"),
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 162 },
                    new RowDefinition() { Height = 64 }
                }
            };

            Grid imageGrid = new Grid()
            {
                Padding = 1,
                BackgroundColor = Color.FromHex("#e4e4e4"),
            };

            Image postImage = new Image();
            postImage.Aspect = Aspect.Fill;
            postImage.Source = post.ImagePath;

            Grid contentOuterGrid = new Grid()
            {
                BackgroundColor = Color.FromHex("#ffffff"),
                RowSpacing = 0
            };

            Grid contentGrid = new Grid()
            {
                Padding = 15,
                RowSpacing = 0,
                RowDefinitions = new RowDefinitionCollection() {
                    new RowDefinition() { Height = 20 },
                    new RowDefinition() { Height = 4 },
                    new RowDefinition() { Height = 20 }
                }
            };

            ExtendedLabel title = new ExtendedLabel()
            {
                Text = post.Title.Rendered,
                Style = (Style)Application.Current.Resources["CardTitleLabelStyle"]

            };

            ExtendedLabel readlink = new ExtendedLabel()
            {
                Text = "Read the latest issue...",
                Style = (Style)Application.Current.Resources["CardReadLinkStyle"]
            };

            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += (s, e) =>
            {
                Device.OpenUri(new Uri(post.Link));
            };
            readlink.GestureRecognizers.Add(tapGestureRecognizer);

            contentGrid.Children.Add(title, 0, 1, 0, 1);
            contentGrid.Children.Add(readlink, 0, 1, 2, 3);

            contentOuterGrid.Children.Add(contentGrid, 0, 1, 0, 1);

            imageGrid.Children.Add(postImage, 0, 1, 0, 1);

            mainGrid.Children.Add(imageGrid, 0, 1, 0, 1);
            mainGrid.Children.Add(contentOuterGrid, 0, 1, 1, 2);

            parent.Children.Add(mainGrid, 0, 1, 0, 1);
            return parent;
        }
        public string Title
        {
            get { return "Welcome"; }
        }
        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }
    }
}
