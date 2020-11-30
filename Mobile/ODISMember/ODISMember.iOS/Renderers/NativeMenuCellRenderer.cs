using Foundation;
using ODISMember.Common;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer (typeof(CustomMenuViewCell), typeof(NativeMenuCellRenderer))]
namespace ODISMember.iOS.Renderers
{
    public class NativeMenuCellRenderer : ViewCellRenderer
    {
       // static NSString rid = new NSString("NativeCell");

        public override UITableViewCell GetCell(Xamarin.Forms.Cell item, UITableViewCell reusableCell, UITableView tv)
        {
            var cell = base.GetCell(item, reusableCell, tv);
            cell.SelectedBackgroundView = new UIView
            {
                BackgroundColor = Color.FromHex("#222233").ToUIColor()
            };
            //cell.SelectionStyle = UITableViewCellSelectionStyle.None;
            return cell;
        }
    }
}