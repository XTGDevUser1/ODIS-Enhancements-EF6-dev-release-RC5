using Newtonsoft.Json;
using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.CustomCell;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Pages.Tabs;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember
{
    public partial class History : ContentView, ITabView
    {
        public RangeEnabledObservableCollection<MemberHistoryModel> HistoryList
        {
            get;
            set;
        }

        public string Title
        {
            get
            {
                return "History";
            }
        }
        BaseContentPage Parent;
        public History(BaseContentPage parent)
        {
            InitializeComponent();
            Parent = parent;
            HistoryList = new RangeEnabledObservableCollection<MemberHistoryModel>();
            listHistory.ItemsSource = HistoryList;
            listHistory.ItemSelected += ListHistory_ItemSelected;
            listHistory.ItemTemplate = new DataTemplate(() => new HistoryCell(parent));
            listHistory.SeparatorVisibility = SeparatorVisibility.None;
            listHistory.BackgroundColor = Color.White;
           // listHistory.SeparatorColor = ColorResources.ListSeparatorColor;
            LoadData();
        }

        private void LoadData()
        {
            HUD load = new HUD("Loading...");
            MemberHelper memberHelper = new MemberHelper();
            var result = memberHelper.GetMemberHistory();

            result.ContinueWith(x =>
            {
                if (x.IsCompleted && !x.IsFaulted)
                {
                    OperationResult operationResult = x.Result;

                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        if (operationResult.Data != null)
                        {
                            List<MemberHistoryModel> history = JsonConvert.DeserializeObject<List<MemberHistoryModel>>(operationResult.Data.ToString());
                            HistoryList.Clear();
                            HistoryList.InsertRange(history);
                            if (HistoryList.Count == 0)
                            {
                                Device.BeginInvokeOnMainThread(() => {
                                    lblNoRecords.IsVisible = true;
                                });
                                
                            }
                        }
                        else
                        {
                            Device.BeginInvokeOnMainThread(() => {
                                lblNoRecords.IsVisible = true;
                            });
                        }
                        load.Dismiss();
                    }
                    else
                    {
                        Device.BeginInvokeOnMainThread(() => {
                            lblNoRecords.IsVisible = true;
                        });
                        ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                        load.Dismiss();
                    }
                }
                else
                {
                    load.Dismiss();
                }

            });
        }
       
        void ListHistory_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            listHistory.SelectedItem = null;
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        public void InitializeToolbar()
        {
           
        }
    }
}
