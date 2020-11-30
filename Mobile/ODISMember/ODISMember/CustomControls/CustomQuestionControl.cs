using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class CustomQuestionControl : StackLayout
    {
        public Question mQuestion { get; set; }
        public ExtendedLabel QuestionTitle
        {
            get;
            set;
        }
        //public ExtendedEntry Entry
        //{
        //    get;
        //    set;
        //}
        public LabelEntryVertical Entry
        {
            get;
            set;
        }
        
        public CustomDatePicker DatePicker
        {
            get;
            set;
        }
        public int QuestionId
        {
            get;
            set;
        }
        public ExtendedLabel LabelError
        {
            get;
            set;
        }                
        public object Answer
        {
            get;
            set;
        }
        public ExtendedEditor Editor { get; set; }
        public void SetAnswer(object answer)
        {
            this.Answer = answer;
            Validate();            
        }
        public CustomQuestionControl(Question question,string serviceType)
        {
            this.Spacing = 20;
            mQuestion = question;
            CachedImage serviceImage = new CachedImage()
            {
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                HeightRequest=App.ScreenHeight/3,
                TransparencyEnabled = false,
                VerticalOptions = LayoutOptions.CenterAndExpand
            };
            this.Children.Add(serviceImage);
            if (serviceType.ToLower() == "tow")
            {
                serviceImage.Source = ImagePathResources.TowServiceQuestions;
            }
            else if (serviceType.ToLower() == "tire")
            {
                serviceImage.Source = ImagePathResources.TireServiceQuestions;
            }
            else if (serviceType.ToLower() == "lockout")
            {
                serviceImage.Source = ImagePathResources.LockoutServiceQuestions;
            }
            else if (serviceType.ToLower() == "fluid")
            {
                serviceImage.Source = ImagePathResources.FluidServiceQuestions;
            }
            else if (serviceType.ToLower() == "jump")
            {
                serviceImage.Source = ImagePathResources.JumpServiceQuestions;
            }
            else if (serviceType.ToLower() == "winch")
            {
                serviceImage.Source = ImagePathResources.WinchServiceQuestions;
            }


            QuestionTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Center,
                Text = mQuestion.Text
            };
            QuestionId = mQuestion.ProductCategoryQuestionId;
            this.Children.Add(QuestionTitle);
            if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Textbox ||
                question.ControlType == Entities.Constants.DynamicFieldsControlType.Phone ||
                question.ControlType == Entities.Constants.DynamicFieldsControlType.Dropdown ||
                question.ControlType == Entities.Constants.DynamicFieldsControlType.Combobox)
            {
                //Entry = new ExtendedEntry()
                //{
                //    Font = FontResources.EntryLabelEntryFont,
                //    HorizontalOptions = LayoutOptions.FillAndExpand,
                //    HasBorder = true,
                //    XAlign = TextAlignment.Center,
                //    TextColor = ColorResources.EntryLabelValueColor,
                //    BackgroundColor = Color.White
                //};
                Entry = new LabelEntryVertical()
                {
                    IsLabelVisible = false
                };
                Entry.EntryValue.TextChanged += Entry_TextChanged;
                if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Dropdown ||
                    question.ControlType == Entities.Constants.DynamicFieldsControlType.Combobox)
                {
                    Entry.EntryValue.Focused += Entry_Focused;
                }
                if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Phone)
                {
                    Entry.KeyboardEntry = Keyboard.Telephone;
                }
                this.Children.Add(Entry);
            }
            else if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Textarea)
            {
                Editor = new ExtendedEditor()
                {
                    Font = FontResources.EntryLabelEntryFont,
                    HorizontalOptions = LayoutOptions.FillAndExpand,
                    TextColor = ColorResources.EntryLabelValueColor
                };
                Editor.TextChanged += (object sender, TextChangedEventArgs e) =>
                {
                    SetAnswer(e.NewTextValue);
                };
                this.Children.Add(Editor);
            }
            else if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Datepicker ||
                question.ControlType == Entities.Constants.DynamicFieldsControlType.DatePicker)
            {
                DatePicker = new CustomDatePicker
                {
                    Format = Constants.DateFormat,
                    VerticalOptions = LayoutOptions.CenterAndExpand,
                    HorizontalOptions = LayoutOptions.CenterAndExpand
                };
                DatePicker.DateEntry.TextChanged += (object sender, TextChangedEventArgs e) =>
                {
                    SetAnswer(Convert.ToDateTime(e.NewTextValue));
                };
                this.Children.Add(DatePicker);
            }
            else if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Radio)
            {
                //BindableRadioGroup memberPlanRadiouGroup = new BindableRadioGroup();                
                //memberPlanRadiouGroup.ItemsSource = mQuestion.DropDownValues.ToDictionary(pair => pair.Name, pair => pair.Value).Values; 
                //this.Children.Add(memberPlanRadiouGroup);
                //memberPlanRadiouGroup.CheckedChanged += memberPlanRadiouGroup_CheckedChanged;

                XLabs.Forms.Controls.BindableRadioGroup memberPlanRadiouGroup = new XLabs.Forms.Controls.BindableRadioGroup();
                memberPlanRadiouGroup.TextColor = ColorResources.EntryLabelTextColor;
                //memberPlanRadiouGroup.FontName = FontResources.BaseLightFontName;
                //memberPlanRadiouGroup.FontSize = 16;
                memberPlanRadiouGroup.ItemsSource = mQuestion.DropDownValues.ToDictionary(pair => pair.Name, pair => pair.Value).Values;
                this.Children.Add(memberPlanRadiouGroup);
                memberPlanRadiouGroup.CheckedChanged += memberPlanRadiouGroup_CheckedChanged;

            }
            /*else if (question.ControlType == Entities.Constants.DynamicFieldsControlType.Checkbox)
            {
                //SC:In Progress
            }*/

            //Adding error label
            LabelError = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["EntryLabelLabelStyle"],
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                TextColor = ColorResources.LabelErrorTextColor
            };

            this.Children.Add(LabelError);
        }
        public bool Validate()
        {           
            if(Answer == null || (Answer as string != null && string.IsNullOrEmpty(Answer.ToString())))
            {
                LabelError.Text = "* Please Answer to continue";
                return false;
            }
            LabelError.Text = string.Empty;
            return true;
        }
        void memberPlanRadiouGroup_CheckedChanged(object sender, int e)
        {
            var radio = sender as XLabs.Forms.Controls.CustomRadioButton;
            if (radio != null)
            {
                SetAnswer(radio.Text);
            }
        }

        private void Entry_TextChanged(object sender, TextChangedEventArgs e)
        {
            SetAnswer(e.NewTextValue);
        }

        private void Entry_Focused(object sender, FocusEventArgs e)
        {
            if (e.IsFocused)
            {
                CustomDropDownForQuestions dropDown = new CustomDropDownForQuestions();
                dropDown.Title = "Select";
                dropDown.ItemSource = mQuestion.DropDownValues;
                dropDown.OnItemSelect += DropDown_OnItemSelect; ;
                Navigation.PushAsync(dropDown);
            }
        }

        private void DropDown_OnItemSelect(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                var selectItem = (Answer)e.SelectedItem;
                Entry.EntryValue.Text = selectItem.Value;
                Entry.EntryValue.Unfocus();
            }
        }
    }
}
