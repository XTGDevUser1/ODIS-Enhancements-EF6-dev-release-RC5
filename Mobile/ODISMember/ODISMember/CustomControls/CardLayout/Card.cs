using System;

using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls.CardLayout
{
	public class Card
	{
		//public CardStatus Status { get; set; }

		public FileImageSource StatusMessageFileSource { get; set; }

		public string StatusMessage { get; set; }

		public FileImageSource ActionMessageFileSource { get; set; }

		public string ActionMessage { get; set; }

		public string Title { get; set; }

		public string Description { get; set; }

		public ContentView MessageView { get; set; }

		public ContentView ActionView { get; set; }

		public DateTime Date { get; set; }

		public int DirationInMinutes { get; set; }

        public string PersonName { get; set; }

    }

	public static class CardStatus
	{
        public const int Entry = 1;
        public const int Submitted = 2;
        public const int Dispatched = 3;
        public const int Complete = 4;
        public const int Cancelled = 5;
        public const int Other = 6;
    }
}