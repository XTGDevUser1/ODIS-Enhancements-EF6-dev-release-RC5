using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.CustomControls;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Widgets
{
   public class LabelDropdownEntryHorizontal : StackLayout
    {
        public PhoneEntry EntryValue
        {
            get;
            set;
        }
        public ExtendedEntry EntryValueDropdown
        {
            get;
            set;
        }
        public ExtendedLabel LabelTitle
        {
            get;
            set;
        }
        public ExtendedLabel LabelError
        {
            get;
            set;
        }        
        public EventHandler Validate
        {
            get;
            set;
        }
        public string Key
        {
            get { return SelectedItem != null ? SelectedItem.Value.Key : string.Empty; }
        }
        public string Value
        {
            get { return SelectedItem != null ? SelectedItem.Value.Value : string.Empty; }
        }

        public Grid GridView;
        StackLayout DropdownLayout;
        public event EventHandler<TextChangedEventArgs> OnDropDownSelection;
        public LabelDropdownEntryHorizontal()
        {
            this.Spacing = 0;
           // Padding = new Thickness(5, 5, 5, 5);
            LabelTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["HeaderLineStyle"],
                HorizontalTextAlignment = TextAlignment.Center
            };
            EntryValue = new PhoneEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                HorizontalTextAlignment = TextAlignment.Start,
                TextColor = ColorResources.EntryLabelValueColor
            };
            EntryValue.TextChanged += EntryValue_TextChanged; 

            EntryValueDropdown = new ExtendedEntry()
            {
                Font = FontResources.EntryLabelEntryFont,
                HorizontalOptions = LayoutOptions.Start,
                HorizontalTextAlignment = TextAlignment.Start,
                TextColor = ColorResources.EntryLabelValueColor
            };
            EntryValueDropdown.TextChanged += EntryValueDropdown_TextChanged;


            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor
            };

            EntryValueDropdown.Focused += EntryValueDropdown_Focused;
            EntryValueDropdown.LeftSwipe = (object s, EventArgs e) => {

            };
            EntryValueDropdown.RightSwipe = (object s, EventArgs e) => {

            };

            GridView = new Grid
            {
                Padding=0,
               HorizontalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions =
                {
                    new RowDefinition { Height = GridLength.Auto },
                    new RowDefinition { Height = GridLength.Auto },
                    new RowDefinition { Height = GridLength.Auto }
                },
                ColumnDefinitions =
                {
                    new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }
                }
            };

            DropdownLayout = new StackLayout() {
                Orientation = StackOrientation.Horizontal,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.White,
                Padding = new Thickness(5,5,5,0)
            };
            StackLayout stackTitle = new StackLayout()
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = Color.Transparent,
                Padding = new Thickness(8)
            };
            DropdownLayout.Children.Add(EntryValueDropdown);
            DropdownLayout.Children.Add(EntryValue);
            stackTitle.Children.Add(LabelTitle);

            GridView.Children.Add(stackTitle, 0, 0);
            GridView.Children.Add(DropdownLayout, 0, 1);
            GridView.Children.Add(LabelError, 0, 2);
            this.Children.Add(GridView);
        }
        public bool onValidate()
        {
            Validate.Invoke(new object(), EventArgs.Empty);
            return IsValid;
        }
        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            EntryText = e.NewTextValue;
        }
        private void EntryValueDropdown_Focused(object sender, FocusEventArgs e)
        {
            if (e.IsFocused)
            {
                CustomDropDownList dropDown= new CustomDropDownList();
                dropDown.ItemSource = this.ItemSource;
                dropDown.OnItemSelect -= DropDown_OnItemSelect;
                dropDown.OnItemSelect += DropDown_OnItemSelect;
                this.Navigation.PushAsync(dropDown);
            }
        }

        private void DropDown_OnItemSelect(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                SelectedItem = (KeyValuePair<string, string>)e.SelectedItem;
                if (SelectedItem.Value.Key == "Select")
                {
                    EntryValueDropdown.Text = string.Empty;
                    SelectedItem = null;
                }
                else
                {
                    EntryValueDropdown.Text = SelectedItem.Value.Key;
                }
                EntryValueDropdown.Unfocus();
            }
        }
        
        private void EntryValueDropdown_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrEmpty(e.NewTextValue))
            {
                SelectedItem = null;
            }
            if (OnDropDownSelection != null)
            {
                OnDropDownSelection.Invoke(sender, e);
            }
        }


        public static BindableProperty LabelTextProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.LabelText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.LabelText = newValue;
                });

        public string LabelText
        {
            get { return (string)GetValue(LabelTextProperty); }
            set
            {
                SetValue(LabelTextProperty, value);
                LabelTitle.Text = value;
            }
        }

        public static BindableProperty EntryHintProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.EntryHint,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.EntryHint = newValue;
                });

        public string EntryHint
        {
            get { return (string)GetValue(EntryHintProperty); }
            set
            {
                SetValue(EntryHintProperty, value);
                EntryValue.Placeholder = value;
            }
        }

        public static BindableProperty EntryHintDropdownProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.EntryHintDropdown,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.EntryHintDropdown = newValue;
                });

        public string EntryHintDropdown
        {
            get { return (string)GetValue(EntryHintDropdownProperty); }
            set
            {
                SetValue(EntryHintDropdownProperty, value);
                EntryValueDropdown.Placeholder = value;
            }
        }

        public static BindableProperty EntryTextProperty =
             BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.EntryText,
                 defaultValue: string.Empty,
                 defaultBindingMode: BindingMode.TwoWay,
                 propertyChanging: (bindable, oldValue, newValue) => {
                     var ctrl = (LabelDropdownEntryHorizontal)bindable;
                     ctrl.EntryText = newValue;
                 });

        public string EntryText
        {
            get { return (string)EntryValue.Text; }
            set
            {
                SetValue(EntryTextProperty, value);
                if (!string.IsNullOrEmpty(value))
                    EntryValue.Text = value;
            }
        }
        public static BindableProperty EntryValueDropdownTextProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.EntryValueDropdownText,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.EntryValueDropdownText = newValue;
                });

        public string EntryValueDropdownText
        {
            get { return (string)EntryValueDropdown.Text; }
            set
            {
                SetValue(EntryValueDropdownTextProperty, value);
                EntryValueDropdown.Text = value;
            }
        }


        public static BindableProperty IsValidProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, bool>(ctrl => ctrl.IsValid,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.IsValid = newValue;
                });

        public bool IsValid
        {
            get { return (bool)GetValue(IsValidProperty); }
            set
            {
                SetValue(IsValidProperty, value);
            }
        }

        public static BindableProperty EntryErrorMessageProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, string>(ctrl => ctrl.EntryErrorMessage,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.EntryErrorMessage = newValue;
                });

        public string EntryErrorMessage
        {
            get { return (string)GetValue(EntryErrorMessageProperty); }
            set
            {
                SetValue(EntryErrorMessageProperty, value);
                LabelError.Text = value;
            }
        }

        public static BindableProperty IsLabelVisibleProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, bool>(ctrl => ctrl.IsLabelVisible,
                defaultValue: true,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) => {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.IsLabelVisible = newValue;
                });

        public bool IsLabelVisible
        {
            get { return (bool)GetValue(IsLabelVisibleProperty); }
            set
            {
                SetValue(IsLabelVisibleProperty, value);
                if (value == false)
                {
                    LabelTitle.HeightRequest = 0;
                }
            }
        }
        public static BindableProperty ItemSourceProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, Dictionary<string, string>>(ctrl => ctrl.ItemSource,
                defaultValue: new Dictionary<string, string>(),
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.ItemSource = newValue;
                });

        public Dictionary<string, string> ItemSource
        {
            get { return (Dictionary<string, string>)GetValue(ItemSourceProperty); }
            set
            {
                SetValue(ItemSourceProperty, value);
            }
        }
       

        public static BindableProperty SelectedItemProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, KeyValuePair<string, string>?>(ctrl => ctrl.SelectedItem,
                defaultValue: null,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.SelectedItem = newValue;
                });

        public KeyValuePair<string, string>? SelectedItem
        {
            get { return (KeyValuePair<string, string>?)GetValue(SelectedItemProperty); }
            set
            {
                SetValue(SelectedItemProperty, value);

            }
        }

        public static BindableProperty KeyboardEntryProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, Keyboard>(ctrl => ctrl.KeyboardEntry,
                defaultValue: Keyboard.Text,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.KeyboardEntry = newValue;
                });

        public Keyboard KeyboardEntry
        {
            get { return (Keyboard)GetValue(KeyboardEntryProperty); }
            set
            {
                SetValue(KeyboardEntryProperty, value);
                EntryValue.Keyboard = value;
            }
        }

        public static BindableProperty IsCenterAlignProperty =
           BindableProperty.Create<LabelDropdownEntryHorizontal, bool>(ctrl => ctrl.IsCenterAlign,
               defaultValue: false,
               defaultBindingMode: BindingMode.TwoWay,
               propertyChanging: (bindable, oldValue, newValue) => {
                   var ctrl = (LabelDropdownEntryHorizontal)bindable;
                   ctrl.IsCenterAlign = newValue;
               });

        public bool IsCenterAlign
        {
            get { return (bool)GetValue(IsCenterAlignProperty); }
            set
            {
                SetValue(IsCenterAlignProperty, value);
                if (value == true)
                {
                    if (DropdownLayout != null) {
                        DropdownLayout.HorizontalOptions = LayoutOptions.CenterAndExpand;
                    }
                }
            }
        }


        public static BindableProperty LabelTitleHorizontalTextAlignmentProperty =
            BindableProperty.Create<LabelDropdownEntryHorizontal, TextAlignment>(ctrl => ctrl.LabelTitleHorizontalTextAlignment,
                defaultValue: TextAlignment.Start,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (LabelDropdownEntryHorizontal)bindable;
                    ctrl.LabelTitleHorizontalTextAlignment = newValue;
                });

        public TextAlignment LabelTitleHorizontalTextAlignment
        {
            get { return (TextAlignment)GetValue(LabelTitleHorizontalTextAlignmentProperty); }
            set
            {
                SetValue(LabelTitleHorizontalTextAlignmentProperty, value);
                LabelTitle.HorizontalTextAlignment= value;
            }
        }
    }
}
