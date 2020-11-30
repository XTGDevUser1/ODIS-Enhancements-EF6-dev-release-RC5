using Newtonsoft.Json;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideVehicleServiceQuestions : ContentPage
    {
        public List<RoadsideServiceQuestions> mRoadsideServiceQuestionsList;
        ServiceRequestModel serviceRequestModel;
        string[] possibleTowServiceChangeAnswers = { "multiple flats", "no spare tire" };


        public List<CustomQuestionControl> QuestionControls;
        int NoOfQuestions = 0;
        public RoadsideVehicleServiceQuestions(List<RoadsideServiceQuestions> roadsideServiceQuestionsList, ServiceRequestModel serviceRequestModel)
        {
            InitializeComponent();
            this.serviceRequestModel = serviceRequestModel;
            this.serviceRequestModel.AnswersToServiceQuestions = new List<NameValuePair>();

            mRoadsideServiceQuestionsList = roadsideServiceQuestionsList;
           
            Title = "Questions";
            // QuestionControls = new List<CustomQuestionControl>();
            if (mRoadsideServiceQuestionsList != null)
            {
                foreach (RoadsideServiceQuestions ServiceQuestion in mRoadsideServiceQuestionsList)
                {
                    foreach (Question question in ServiceQuestion.Questions)
                    {
                        CustomQuestionControl customQuestionControl = new CustomQuestionControl(question, serviceRequestModel.ServiceType);
                        customQuestionControl.IsVisible = false;
                        //customQuestionControl.VerticalOptions = LayoutOptions.Center;
                        stackQuestion.Children.Add(customQuestionControl);
                    }
                }
            }
            NoOfQuestions = stackQuestion.Children.Count;
            if (NoOfQuestions > 0)
            stackQuestion.Children[0].IsVisible = true;
            btnPrev.IsVisible = false;

            btnPrev.Clicked += BtnPrev_Clicked;
            btnNext.Clicked += BtnNext_Clicked;
            Global.AddPage(this);
        }

        private async void BtnNext_Clicked(object sender, EventArgs e)
        {           
            var view = stackQuestion.Children.Where(a => a.IsVisible == true).FirstOrDefault();
            if (view != null)
            {
                CustomQuestionControl currentQuestionControl = (CustomQuestionControl)view;
                int currentQuestionIndex = stackQuestion.Children.IndexOf(view);
                if (currentQuestionIndex > -1) {
                    
                    //validating current question
                    var currentAnswer = (stackQuestion.Children[currentQuestionIndex] as CustomQuestionControl).Validate();
                    if (!currentAnswer) //if User not chosen answer we are showing alert 
                    {                        
                        return;
                    }

                    //TFS #1492 :Hardcoded logic
                    if(serviceRequestModel.ServiceType.ToLower() != "tow")
                    {
                        var currentAnswerLower = currentQuestionControl.Answer.ToString().ToLower();
                        foreach (string x in possibleTowServiceChangeAnswers)
                        {
                            if (x.Contains(currentAnswerLower))
                            {
                                var isConvertServiceToTow = await DisplayAlert("Tow Required", "Since multiple tires need to be replaced or you do not have a spare, we need to change your service request to a tow.", "Confirm", "Cancel");
                                if (isConvertServiceToTow)
                                {
                                    //changing service type to "tow"
                                    serviceRequestModel.ServiceType = "Tow";                                    
                                    //loading same questions page with service questions related to tow.
                                    await LoadServiceQuestionsData();
                                    return;
                                }
                                else
                                {
                                    return;
                                }
                            }
                        }
                    }             


                    if ((NoOfQuestions - 1) == currentQuestionIndex)
                    {

                        for (int i = 0; i < stackQuestion.Children.Count;i++)
                        {
                            CustomQuestionControl customQuestionControl = (CustomQuestionControl)stackQuestion.Children[i];
                            serviceRequestModel.AnswersToServiceQuestions.Add(new NameValuePair() { Name = customQuestionControl.QuestionId.ToString(), Value = customQuestionControl.Answer.ToString() });
                        }
                        if (serviceRequestModel.ServiceType.ToLower() == "tow")
                        {
                            Navigation.PushAsync(new RoadsideRequestDestination(serviceRequestModel));
                        }
                        else {
                            Navigation.PushAsync(new ServiceQuestionsSubmit(serviceRequestModel));
                        }
                    }
                    else {
                        stackQuestion.Children[currentQuestionIndex].IsVisible = false;
                        stackQuestion.Children[currentQuestionIndex+1].IsVisible = true;
                        btnPrev.IsVisible = true;
                    }
                }
            }
            
        }

        private void BtnPrev_Clicked(object sender, EventArgs e)
        {
            var view = stackQuestion.Children.Where(a => a.IsVisible == true).FirstOrDefault();
            if (view != null)
            {
                CustomQuestionControl currentQuestionControl = (CustomQuestionControl)view;
                int currentQuestionIndex = stackQuestion.Children.IndexOf(view);
                if (currentQuestionIndex > -1)
                {
                    if (currentQuestionIndex == 1)
                    {
                        btnPrev.IsVisible = false;
                        btnNext.IsVisible = true;
                    }
                    
                    stackQuestion.Children[currentQuestionIndex].IsVisible = false;
                    stackQuestion.Children[currentQuestionIndex - 1].IsVisible = true;
                    
                }
            }
        }

        //TODO: copied from RoadsideVechileService.cs page need to combine this method.
        private async Task LoadServiceQuestionsData()
        {
            MemberHelper memberHelper = new MemberHelper();
            using (new HUD("Loading..."))
            {
                List<RoadsideServiceQuestions> roadsideServiceQuestionsList = new List<RoadsideServiceQuestions>();

                OperationResult operationResult = await memberHelper.GetVehicleServiceQuestions(serviceRequestModel.ServiceType, serviceRequestModel.VehicleCategory, serviceRequestModel.VehicleType);

                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                {
                    roadsideServiceQuestionsList.Clear();
                    roadsideServiceQuestionsList = JsonConvert.DeserializeObject<List<RoadsideServiceQuestions>>(operationResult.Data.ToString());

                    //removing current questions page from navigation stack
                    Navigation.PopAsync();

                    if (roadsideServiceQuestionsList != null && roadsideServiceQuestionsList.Count > 0 && roadsideServiceQuestionsList[0].Questions.Count > 0)
                    {
                        await Navigation.PushAsync(new RoadsideVehicleServiceQuestions(roadsideServiceQuestionsList, serviceRequestModel));
                    }
                    else
                    {
                        if (serviceRequestModel.ServiceType.ToLower() == "tow")
                        {
                            await Navigation.PushAsync(new RoadsideRequestDestination(serviceRequestModel));
                        }
                        else
                        {
                            await Navigation.PushAsync(new ServiceQuestionsSubmit(serviceRequestModel));
                        }
                    }
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }
       
    }
}
