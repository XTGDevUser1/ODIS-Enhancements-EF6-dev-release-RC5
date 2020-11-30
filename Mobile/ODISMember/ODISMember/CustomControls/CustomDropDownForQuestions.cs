using ODISMember.Entities.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class CustomDropDownForQuestions : ContentPage
    {
        public ListView DropDown;
        public SearchBar Search;
        // public EventHandler OnItemSelect;
        public event EventHandler<SelectedItemChangedEventArgs> OnItemSelect;
        public CustomDropDownForQuestions()
        {

            Search = new SearchBar()
            {
                Placeholder = "Search",
                SearchCommand = new Command(() =>
                {
                    if (string.IsNullOrEmpty(Search.Text))
                    {
                        DropDown.ItemsSource = ItemSource;
                    }
                    else
                    {
                        var result = ItemSource.Where(a => a.Name.ToLower().Contains(Search.Text.ToLower())).ToList();
                        DropDown.ItemsSource = result;
                    }
                })
            };

            Search.TextChanged += Search_TextChanged;
            DropDown = new ListView()
            {
                HasUnevenRows = true,
                SeparatorColor = Color.Silver,
                ItemTemplate = new DataTemplate(() =>
                {
                    ExtendedLabel nameLabel = new ExtendedLabel()
                    {
                        Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                        HorizontalTextAlignment = TextAlignment.Start

                    };
                    nameLabel.SetBinding(ExtendedLabel.TextProperty, "Name");
                    return new ViewCell
                    {
                        View = new StackLayout
                        {
                            Children =
                                {
                                    new StackLayout
                                    {
                                        Spacing = 0,
                                        Padding = new Thickness(5),
                                        Children =
                                        {
                                            nameLabel
                                        }
                                    }
                                }
                        }
                    };
                })
            };
            DropDown.ItemSelected += DropDown_ItemSelected;

            StackLayout stack = new StackLayout();
            stack.Children.Add(Search);
            stack.Children.Add(DropDown);
            this.Content = stack;
        }

        private void Search_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrEmpty(Search.Text))
            {
                DropDown.ItemsSource = ItemSource;
            }
            else
            {
                var result = ItemSource.Where(a => a.Name.ToLower().Contains(Search.Text.ToLower())).ToList();
                DropDown.ItemsSource = result;
            }
        }

        private void DropDown_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (OnItemSelect != null)
            {
                OnItemSelect(sender, e);
            }
            this.Navigation.PopAsync();
        }

        public static BindableProperty ItemSourceProperty =
            BindableProperty.Create<CustomDropDownForQuestions, List<Answer>>(ctrl => ctrl.ItemSource,
                defaultValue: new List<Answer>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (CustomDropDownForQuestions)bindable;
                    ctrl.ItemSource = newValue;
                });

        public List<Answer> ItemSource
        {
            get { return (List<Answer>)GetValue(ItemSourceProperty); }
            set
            {
                SetValue(ItemSourceProperty, value);
                if (DropDown != null)
                    DropDown.ItemsSource = value;
            }
        }
    }
}
