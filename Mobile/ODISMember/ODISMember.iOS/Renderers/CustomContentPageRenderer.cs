using ODISMember.CustomControls;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;
using System.Linq;
[assembly: ExportRenderer(typeof(CustomContentPage), typeof(CustomContentPageRenderer))]
namespace ODISMember.iOS.Renderers
{
    public class CustomContentPageRenderer : PageRenderer
    {
        bool isFirst;
        public CustomContentPageRenderer() {
            isFirst = true;
        }
        public new CustomContentPage Element
        {
            get { return (CustomContentPage)base.Element; }
        }

        public override void ViewWillAppear(bool animated)
        {
            base.ViewWillAppear(animated);
            if (isFirst)
            {
                var LeftNavList = new List<UIKit.UIBarButtonItem>();
                var rightNavList = new List<UIKit.UIBarButtonItem>();

                var navigationItem = this.NavigationController.TopViewController.NavigationItem;

                for (var i = 0; i < Element.ToolbarItems.Count; i++)
                {

                    var reorder = (Element.ToolbarItems.Count - 1);
                    var ItemPriority = Element.ToolbarItems[reorder - i].Priority;

                    if (ItemPriority == 1)
                    {
                        if (navigationItem != null && navigationItem.RightBarButtonItems.Count() > i)
                        {
                            UIKit.UIBarButtonItem LeftNavItems = navigationItem.RightBarButtonItems[i];
                            LeftNavList.Add(LeftNavItems);
                        }
                    }
                    else if (ItemPriority == 0)
                    {
                        if (navigationItem != null && navigationItem.RightBarButtonItems.Count() > i)
                        {
                            UIKit.UIBarButtonItem RightNavItems = navigationItem.RightBarButtonItems[i];
                            rightNavList.Add(RightNavItems);
                        }
                    }
                }
                if (LeftNavList.Count > 0)
                {
                    navigationItem.SetLeftBarButtonItems(LeftNavList.ToArray(), false);
                }
                if (rightNavList.Count > 0)
                {
                    navigationItem.SetRightBarButtonItems(rightNavList.ToArray(), false);
                }
                isFirst = false;
            }
        }
    }
}