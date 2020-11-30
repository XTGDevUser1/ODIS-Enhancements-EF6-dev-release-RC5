using ODISMember.CustomControls;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Widgets
{
    public class ImageTextRadioButton : Grid
    {
        List<RadioButtonItem> RadioButtonItemSource;
        public event EventHandler OnImageClick;
        double ItemSize;
        public ImageTextRadioButton(List<RadioButtonItem> radiobuttons)
        {
            ItemSize = (App.ScreenWidth / 3);
            RadioButtonItemSource = radiobuttons;
            Padding = new Thickness(10,5,10,5);
            ColumnSpacing = 5;
            RowSpacing = 5;
            ColumnDefinitions = new ColumnDefinitionCollection {
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) },
                };
            AddRowsDefination();
        }
        private void AddRowsDefination()
        {
            int total = RadioButtonItemSource.Count;
            int rows = total / 3;
            int addRow = total % 3;
            if (addRow != 0)
            {
                rows = rows + 1;
            }
            
            for (int i = 1; i <= rows; i++)
            {
                this.RowDefinitions.Add(new RowDefinition { Height = new GridLength(ItemSize) });
            }
            BuildCategories();
        }

        private void BuildCategories()
        {
            for (var index = 0; index < RadioButtonItemSource.Count; index++)
            {
                var column = index % 3;
                var row = (int)Math.Floor(index / 3f);
                var item = RadioButtonItemSource[index];
                ImageTextView cellLayout = new ImageTextView()
                {
                    BindingContext = item,
                    UnSelectedImageUrl = item.UnSelectedImageURL,
                    SelectedImageUrl = item.SelectedImageURL,
                    LabelText = item.Text,
                    HeightRequest = ItemSize
                };
                cellLayout.ImageClick += CellLayout_ImageClick;
                this.Children.Add(cellLayout, column, row);
            }
        }

        private void CellLayout_ImageClick(object sender, EventArgs e)
        {
            foreach (var view in this.Children) {
                ImageTextView imageTextView = (ImageTextView)view;
                imageTextView.UnSelectImage();
            }
            ImageTextView selectedImageTextView  = (ImageTextView)sender;
            selectedImageTextView.SelectImage();
            if (OnImageClick != null)
            {
                OnImageClick.Invoke(selectedImageTextView.BindingContext, e);
            }
        }
    }
}
