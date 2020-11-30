using System;
using System.Linq;
using Xamarin.Forms;
using Plugin.Toasts;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using ODISMember.CustomControls;
using ODISMember.Entities.Model;
using ODISMember.Entities;
using System.Threading.Tasks;
using Newtonsoft.Json;
using ODISMember.Entities.Table;
using ODISMember.Helpers.UIHelpers;

namespace ODISMember
{
    public static class Global
    {
        public static AccountModel CurrentMember = null;
        public static List<Associate> CurrentAssociateMembers = null;
        public static Associate CurrentAssociateMember = null;
        public static Dictionary<string, string> ApplicationSettings;
        public static byte[] CroppedImage = null;
        public static bool IsGotoSetting = false;
        public static string ServiceRequestPhoneNumber = string.Empty;
        public static List<Page> Pages = new List<Page>();
        public static bool IsFeedBackPageActive = false;
        public static void AddPage(Page page)
        {
            Pages.Add(page);
        }
        public static void RemovePage(Page page)
        {
            Pages.Remove(page);
        }
        public static void RemovePages(Page page)
        {
            //var existingPages = page.Navigation.NavigationStack.ToList();
            //foreach (Page p in Pages)
            //{
            //    page.Navigation.RemovePage(p);
            //}
            Device.BeginInvokeOnMainThread(() =>
            {
                foreach (Page p in Pages)
                {
                    bool isExists = page.Navigation.NavigationStack.Contains(p);
                    if (isExists)
                    {
                        page.Navigation.RemovePage(p);
                    }
                }
                Pages.Clear();
            });

        }

        public static void RemoveSpecificPage(Page currentPage, string removePage)
        {
            var existingPages = currentPage.Navigation.NavigationStack.ToList();
            foreach (Page p in existingPages)
            {
                if (p.GetType().Name == removePage)
                {
                    currentPage.Navigation.RemovePage(p);
                }
            }
        }

        public static void GetAllMembers()
        {
            MemberHelper memberHelper = new MemberHelper();
            MemberAssociate memberAssociates = memberHelper.GetLocalMembers();
            if (memberAssociates != null)
            {
                if (Global.CurrentAssociateMembers == null)
                {
                    Global.CurrentAssociateMembers = new List<Associate>();
                }
                else
                {
                    Global.CurrentAssociateMembers.Clear();
                }
                List<Associate> associates = JsonConvert.DeserializeObject<List<Associate>>(memberAssociates.MemberAssociateInfo.ToString());
                if (associates != null)
                {
                    foreach (var item in associates)
                    {
                        if (!string.IsNullOrEmpty(item.DateOfBirth) && (Convert.ToDateTime(item.DateOfBirth).Date == Convert.ToDateTime(Constants.DefaultAptifyDate).Date))
                        {
                            item.DateOfBirth = string.Empty;
                        }
                        Global.CurrentAssociateMembers.Add(item);
                    }
                    if (Global.CurrentAssociateMembers.Count > 0)
                    {
                        EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.REFRESH_MEMBERS));
                    }
                    if (Global.CurrentAssociateMembers != null && Global.CurrentAssociateMembers.Count > 0)
                    {
                        if (Global.CurrentAssociateMember == null)
                        {
                            Global.CurrentAssociateMember = new Associate();
                        }
                        Global.CurrentAssociateMember = Global.CurrentAssociateMembers.Where(a => a.MemberNumber == Constants.MEMBER_NUMBER).FirstOrDefault();

                        EventDispatcher.RaiseEvent(Global.CurrentAssociateMember, new RefreshEventArgs(AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS));

                    }
                }
            }
        }
        public static void GetMembership()
        {
            MemberHelper memberHelper = new MemberHelper();
            ODISMember.Entities.Table.Membership membership = memberHelper.GetMembershipLocal();
            if (membership != null)
            {
                if (Global.CurrentMember == null)
                {
                    Global.CurrentMember = new AccountModel();
                }
                Global.CurrentMember = JsonConvert.DeserializeObject<AccountModel>(membership.MembershipInfo);
                EventDispatcher.RaiseEvent(Global.CurrentMember, new RefreshEventArgs(AppConstants.Event.REFRESH_MEMBERSHIP_DETAILS));
            }
        }
        public static void GetApplicationSettings()
        {
            MemberHelper memberHelper = new MemberHelper();
            List<ODISMember.Entities.Table.ApplicationSettingsTable> applicationSetting = memberHelper.GetLocalApplicationSettings();
            if (applicationSetting != null)
            {
                Global.ApplicationSettings = new Dictionary<string, string>();
                Global.ApplicationSettings = applicationSetting.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
            }
        }
    }

    public class RangeEnabledObservableCollection<T> : ObservableCollection<T>
    {
        public void InsertRange(IEnumerable<T> items)
        {
            this.CheckReentrancy();
            foreach (var item in items)
                this.Items.Add(item);
            this.OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
        }
    }
}


