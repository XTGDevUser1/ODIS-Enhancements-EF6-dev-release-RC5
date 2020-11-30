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
    public partial class Social : ContentView, ITabView
    {
        BaseContentPage Parent;
        public Social(BaseContentPage parent)
        {
            InitializeComponent();
            this.Parent = parent;
			//parent.Title = "Social";
        }

        public string Title
        {
            get { return "Social"; }
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }
    }
}
