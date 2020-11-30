using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{
    public class RadioGroupViewModel : INotifyPropertyChanged
    {
		public RadioGroupViewModel()
        {
            selectedIndex = -1;
        }

		private Dictionary<int, string> groupList;
		public Dictionary<int, string> GroupList
        {
			get { return groupList; }
            set
            {
				groupList = value;
				NotifyPropertyChanged("GroupList");
            }
        }

        private int selectedIndex;
        public int SelectedIndex
        {
            get { return selectedIndex; }
            set
            {
                if (value == selectedIndex) return;
                selectedIndex = value;
                NotifyPropertyChanged("SelectedIndex");
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        public void NotifyPropertyChanged(String propertyName)
        {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (null != handler)
            {
                handler(this, new PropertyChangedEventArgs(propertyName));
            }
        }
    }
}
