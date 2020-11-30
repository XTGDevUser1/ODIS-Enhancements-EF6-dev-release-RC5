using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Models
{
    /// <summary>
    /// Sticky Note Model
    /// </summary>
    [Serializable]
    public class StickyNoteModel
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="StickyNoteModel"/> class.
        /// </summary>
        public StickyNoteModel()
        {
            StickyText = string.Empty;
            Left = "0px";
            Top = "0px";
            IsOpen = false;
        }

        /// <summary>
        /// Gets or sets the sticky text.
        /// </summary>
        /// <value>
        /// The sticky text.
        /// </value>
        public string StickyText { get; set; }

        /// <summary>
        /// Gets or sets the left.
        /// </summary>
        /// <value>
        /// The left.
        /// </value>
        public string Left { get; set; }

        /// <summary>
        /// Gets or sets the top.
        /// </summary>
        /// <value>
        /// The top.
        /// </value>
        public string Top { get; set; }

        /// <summary>
        /// Gets or sets the is open.
        /// </summary>
        /// <value>
        /// The is open.
        /// </value>
        public bool? IsOpen { get; set; } 
    }
}