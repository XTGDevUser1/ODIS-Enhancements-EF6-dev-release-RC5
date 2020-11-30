using ODISMember.Common;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class MemberInActive : ContentView, ITabView
    {
        BaseContentPage Parent;
        public MemberInActive(BaseContentPage parent)
        {
            Parent = parent;
            InitializeComponent();
        }

        public string Title
        {
            get
            {
                return "";
            }
        }

        public void InitializeToolbar()
        {
           
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
    }
}
