using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace Martex.DMS.BLL.Model
{
    public class ProfileImageModel
    {
        public HttpPostedFileBase ProfileImage { get; set; }
        public int X1 { get; set; }
        public int X2 { get; set; }
        public int Y1 { get; set; }
        public int Y2 { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
    }

    public class ImageLoadModel
    {
        public int? entityID { get; set; }
        public string entity { get; set; }
    }
}
