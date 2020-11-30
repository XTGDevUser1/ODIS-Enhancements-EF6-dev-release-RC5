using System;
using System.Collections.Generic;
using System.Linq;
using Xamarin.Forms;

namespace ODISMember.Entities.Model
{
    public class SwitcherPageViewModel : BaseViewModel
    {
        public SwitcherPageViewModel()
        {
            Pages = new List<IntraductionViewModel>() {
                new IntraductionViewModel {  SlideNumber = 1, Title = "Let us keep you up to date.", Description = "When you are stuck on the side of the road you want to know when help is arriving. We will send you an alert when help is on the way.", Background = Color.White, ImageSource = "notificationDualColor.png" },
                new IntraductionViewModel {  SlideNumber = 2, Title = "Get help fast!", Description = "We use your location to find you quickly and accurately. We only use your location when you are using the app. Your privacy is important to us.", Background = Color.White, ImageSource = "alertDualColor.png" }
                    };

            CurrentPage = Pages.First();
        }

        IEnumerable<IntraductionViewModel> _pages;
        public IEnumerable<IntraductionViewModel> Pages
        {
            get
            {
                return _pages;
            }
            set
            {
                SetObservableProperty(ref _pages, value);
                CurrentPage = Pages.FirstOrDefault();
            }
        }

        IntraductionViewModel _currentPage;
        public IntraductionViewModel CurrentPage
        {
            get
            {
                return _currentPage;
            }
            set
            {
                SetObservableProperty(ref _currentPage, value);
            }
        }
    }

    public class IntraductionViewModel : BaseViewModel, ITabProvider
    {
        public IntraductionViewModel() { }

        public int SlideNumber { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public Color Background { get; set; }
        public string ImageSource { get; set; }
    }
}

