using ODISMember.Classes;
using ODISMember.Entities.Model;
using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Pages.Walkthrough
{
    public class IntraductionView : ContentView
    {
        public IntraductionView()
        {
                    
        }

        protected override void OnBindingContextChanged()
        {
            IntraductionViewModel view = this.BindingContext as IntraductionViewModel;            

            var label = new ExtendedLabel
            {
                HorizontalTextAlignment = TextAlignment.Center,                
                Text = view.Title,
                Style = (Style)Application.Current.Resources["HeaderLabelStyle"],
                TextColor = Color.Black
            };

			var description = new ExtendedLabel
			{
                HorizontalTextAlignment = TextAlignment.Center,				
				Text = view.Description,
                Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"]
            };

            var image = new Image();

            image.Source = view.ImageSource;
            image.HorizontalOptions = LayoutOptions.Center;
            image.VerticalOptions = LayoutOptions.Center;
			image.WidthRequest = 150;
			image.HeightRequest = 150;

	
			ScrollView scrollView = new ScrollView();

			Content = new ScrollView(){
				Content = new StackLayout {
					Spacing = 20,
					VerticalOptions = LayoutOptions.StartAndExpand,
					Children = {
						image,
						label,
						description
					},
                    Padding = new Thickness(0, 50, 0, 0)
				}
			}; 
            

            base.OnBindingContextChanged();
        }        
    }
}

