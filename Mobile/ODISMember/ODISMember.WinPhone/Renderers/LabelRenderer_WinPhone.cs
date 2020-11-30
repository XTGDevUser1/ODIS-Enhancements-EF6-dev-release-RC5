
using ODISMember.WinPhone;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using Xamarin.Forms.Platform.WinPhone;

[assembly: ExportRenderer(typeof(Label), typeof(LabelRenderer_WinPhone))]
namespace ODISMember.WinPhone
{
    public class LabelRenderer_WinPhone : LabelRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Label> e)
        {
            base.OnElementChanged(e);
            var lable = e.NewElement;
            if (lable != null)
            {
                lable.FontFamily = @"\Assets\Fonts\AvenirL-Book.otf#AvenirL Book";
            }
        }
    }
}
