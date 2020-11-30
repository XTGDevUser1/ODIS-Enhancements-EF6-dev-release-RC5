using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Interfaces
{
   public interface IScreenshotManager
    {
        byte[] CaptureAsync();
    }
}
