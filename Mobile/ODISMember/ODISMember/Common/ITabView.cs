using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Common
{
    public interface ITabView
    {
        string Title { get; }
        void ResetToolbar();
        void InitializeToolbar();
    }
}
