using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Widgets;
using System.ComponentModel;

namespace ODISMember.Behaviors
{
	public class CapitalConvertBehavior_LabelEntryHorizontal : Behavior<LabelEntryHorizontal>
    {
       	
		public LabelEntryHorizontal CurrentWidget{
			get;
			set;
		}

		protected override void OnAttachedTo(LabelEntryHorizontal bindable)
        {
			CurrentWidget = bindable;
			CurrentWidget.EntryValue.TextChanged += HandleTextChanged;
        }
		private void HandleTextChanged(object sender, TextChangedEventArgs e)
		{
            if (!string.IsNullOrEmpty(e.NewTextValue))
            {
                CurrentWidget.EntryValue.Text = e.NewTextValue.ToUpper();
            }
        }

		protected override void OnDetachingFrom(LabelEntryHorizontal bindable)
        {
			CurrentWidget.EntryValue.TextChanged -= HandleTextChanged;
        }

    }
}
