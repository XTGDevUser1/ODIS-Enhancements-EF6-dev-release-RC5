using ODISMember.Entities.Model;
using System;
using System.Collections;
using System.Linq;
using Xamarin.Forms;

namespace ODISMember.Pages.Walkthrough
{
    public class PagerIndicatorDots : StackLayout
    {
        private int dotCount = 1;
        private int _selectedIndex;
        public int NoOfDots { get; set; }

        public Color DotColor { get; set; }
        public Color DotSelectedColor { get; set; }
        public double DotSize { get; set; }

        private Action<int, int> OnSelectedIndexChanged;

        public PagerIndicatorDots(Action<int, int> OnSelectedIndexChanged = null)
        {
            HorizontalOptions = LayoutOptions.CenterAndExpand;
            VerticalOptions = LayoutOptions.Center;
            Orientation = StackOrientation.Horizontal;
            //DotColor = Color.Silver;

            this.OnSelectedIndexChanged = OnSelectedIndexChanged;
        }
        public void AddDots()
        {
           for(int i=0;i<NoOfDots;i++)
            {
                CreateDot();
            }
        }
        public void SetActiveDot(int selectedIndex)
        {
            var pagerIndicators = Children.Cast<Button>().ToList();
            foreach (var pi in pagerIndicators)
            {
                UnselectDot(pi);
            }

            if (selectedIndex > -1)
            {
                SelectDot(pagerIndicators[selectedIndex]);
            }
        }

        private void CreateDot()
        {
            //Make one button and add it to the dotLayout
            var dot = new Button
            {
                BorderRadius = Convert.ToInt32(DotSize / 2),
                HeightRequest = DotSize,
                WidthRequest = DotSize,
                BackgroundColor = DotColor
            };
            Children.Add(dot);
        }

        private void CreateTabs()
        {
            foreach (var item in ItemsSource)
            {
                var tab = item as ITabProvider;
                var image = new Image
                {
                    HeightRequest = 42,
                    WidthRequest = 42,
                    BackgroundColor = DotColor,
                    Source = tab.ImageSource,
                };
                Children.Add(image);
            }
        }

        public static BindableProperty ItemsSourceProperty =
            BindableProperty.Create<PagerIndicatorDots, IList>(
                pi => pi.ItemsSource,
                null,
                BindingMode.OneWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    ((PagerIndicatorDots)bindable).ItemsSourceChanging();
                },
                propertyChanged: (bindable, oldValue, newValue) =>
                {
                    ((PagerIndicatorDots)bindable).ItemsSourceChanged();
                }
        );

        public IList ItemsSource
        {
            get
            {
                return (IList)GetValue(ItemsSourceProperty);
            }
            set
            {
                SetValue(ItemsSourceProperty, value);
            }
        }

        public static BindableProperty SelectedItemProperty =
            BindableProperty.Create<PagerIndicatorDots, object>(
                pi => pi.SelectedItem,
                null,
                BindingMode.TwoWay,
                propertyChanged: (bindable, oldValue, newValue) =>
                {
                    ((PagerIndicatorDots)bindable).SelectedItemChanged();
                });

        public object SelectedItem
        {
            get
            {
                return GetValue(SelectedItemProperty);
            }
            set
            {
                SetValue(SelectedItemProperty, value);
            }
        }

        private void ItemsSourceChanging()
        {
            if (ItemsSource != null)
                _selectedIndex = ItemsSource.IndexOf(SelectedItem);
        }

        private void ItemsSourceChanged()
        {
            if (ItemsSource == null) return;

            // Dots *************************************
            var countDelta = ItemsSource.Count - Children.Count;

            if (countDelta > 0)
            {
                for (var i = 0; i < countDelta; i++)
                {
                    CreateDot();
                }
            }
            else if (countDelta < 0)
            {
                for (var i = 0; i < -countDelta; i++)
                {
                    Children.RemoveAt(0);
                }
            }
            //*******************************************
        }

        private void SelectedItemChanged()
        {
            var selectedIndex = ItemsSource.IndexOf(SelectedItem);
            var pagerIndicators = Children.Cast<Button>().ToList();

            OnSelectedIndexChanged(selectedIndex, pagerIndicators.Count);

            foreach (var pi in pagerIndicators)
            {
                UnselectDot(pi);
            }

            if (selectedIndex > -1)
            {
                SelectDot(pagerIndicators[selectedIndex]);
            }
        }

        private void UnselectDot(Button dot)
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                dot.BackgroundColor = DotColor;
                dot.Opacity = 0.5;
            });
        }

        private void SelectDot(Button dot)
        {
            Device.BeginInvokeOnMainThread(() =>
           {
               dot.BackgroundColor = DotSelectedColor;
               dot.Opacity = 1.0;
           });
        }
    }
}