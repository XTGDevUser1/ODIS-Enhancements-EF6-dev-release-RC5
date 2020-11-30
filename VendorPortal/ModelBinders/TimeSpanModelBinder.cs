using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace VendorPortal.ModelBinder
{
    public class TimeSpanModelBinder : IModelBinder
    {
        #region Public Methods
        /// <summary>
        /// Binds the model to a value by using the specified controller context and binding context.
        /// </summary>
        /// <param name="controllerContext">The controller context.</param>
        /// <param name="bindingContext">The binding context.</param>
        /// <returns>
        /// The bound value.
        /// </returns>
        public object BindModel(ControllerContext controllerContext,
            ModelBindingContext bindingContext)
        {
            // Ensure there's incomming data
            var key = bindingContext.ModelName;
            var valueProviderResult = bindingContext.ValueProvider
                .GetValue(key);

            if (valueProviderResult == null ||
                string.IsNullOrEmpty(valueProviderResult
                    .AttemptedValue))
            {
                return null;
            }

            // Preserve it in case we need to redisplay the form
            bindingContext.ModelState
                .SetModelValue(key, valueProviderResult);
            string attemptedValue = valueProviderResult.AttemptedValue;
            
            try
            {
                TimeSpan? ts = null;
                ts = DateTime.ParseExact(attemptedValue, "h:m tt", null).TimeOfDay;
                return ts;
            }
            catch (Exception)
            {
            }

            return null;
        }
        #endregion
    }
}