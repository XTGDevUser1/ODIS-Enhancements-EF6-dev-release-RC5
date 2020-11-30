using System;
using Xamarin.Forms;

namespace ODISMember.Model
{
	public class CustomMenuItem
	{
        public int Id { get; set; }
        public string Title { get; set; }
		public string IconSource { get; set; }
		public Type TargetType { get; set; }
		public Color TextColor{	get; set; }
		public int Position { get; set; }
		public int EventId { get; set;}
		//public bool IsBottomMenu { get;	set; }
	}
}

