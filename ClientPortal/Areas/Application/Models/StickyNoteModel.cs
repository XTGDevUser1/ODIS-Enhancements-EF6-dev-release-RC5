using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace  ClientPortal.Models
{
    [Serializable]
    public class StickyNoteModel
    {
        public StickyNoteModel()
        {
            StickyText = string.Empty;
            Left = "0px";
            Top = "0px";
            IsOpen = false;
        }
        public string StickyText { get; set; }
        public string Left { get; set; }
        public string Top { get; set; }
        public bool? IsOpen { get; set; } 
    }
}