using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace ClientPortal.ActionFilters
{
    /// <summary>
    /// Enumeration for display elements whose display should be controlled via ControlDisplayManager ActionFilter
    /// </summary>
    public enum ControlConstants
    {
        ShowComments,
        ShowStickyNotes,
        ShowCallTimer
    }

    /// <summary>
    /// ActionFilter that helps the view determine which UI element should be made visible.
    /// The list of UI elements that can be made visible (explicitly) is defined by the enumeration - ControlConstants.
    /// </summary>
    [AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public class ControlDisplayManagerAttribute : ActionFilterAttribute
    {

        protected ControlConstants[] uiElements;

        /// <summary>
        /// Initializes a new instance of the <see cref="ControlDisplayManager"/> class.
        /// </summary>
        /// <param name="uiElements">The list of UI elements that should be made visible.</param>
        public ControlDisplayManagerAttribute(params ControlConstants[] uiElements)
        {
            this.uiElements = uiElements;
        }

        /// <summary>
        /// Called by the ASP.NET MVC framework before the action result executes.
        /// Store a value true in the viewdata against the key that is in the list of UI elements supplied to this ActionFilter.
        /// </summary>
        /// <param name="filterContext">The filter context.</param>
        public override void OnResultExecuting(ResultExecutingContext filterContext)
        {
            ViewDataDictionary viewData = filterContext.Controller.ViewData;
            foreach (ControlConstants uiElement in this.uiElements)
            {
                viewData[uiElement.ToString()] = true;
            }
            
            base.OnResultExecuting(filterContext);
        }

    }
}