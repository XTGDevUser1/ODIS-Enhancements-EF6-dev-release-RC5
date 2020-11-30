using Foundation;
using ODISMember.Common;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer (typeof(CustomViewCell), typeof(NativeCellRenderer))]
namespace ODISMember.iOS.Renderers
{
    public class NativeCellRenderer : ViewCellRenderer
    {
       // static NSString rid = new NSString("NativeCell");

        public override UITableViewCell GetCell(Xamarin.Forms.Cell item, UITableViewCell reusableCell, UITableView tv)
        {
            var cell = base.GetCell(item, reusableCell, tv);
            cell.SelectionStyle = UITableViewCellSelectionStyle.None;
            return cell;
        }
    }
}