using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Globalization;

namespace VendorPortal.ModelBinder
{
    /// <summary>
    /// IntegerModelBinder
    /// </summary>
    public class IntegerModelBinder : IModelBinder
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
            string attemptedValue = string.Empty;
            if (valueProviderResult.RawValue.GetType().Name == "String[]")
            {
                attemptedValue = ((string[])valueProviderResult.RawValue)[0];
            }
            if (valueProviderResult.RawValue.GetType().Name == "String")
            {
                attemptedValue = ((string)valueProviderResult.RawValue);
            }
            int actualValue = 0;
            try
            {
                actualValue = int.Parse(attemptedValue, NumberStyles.AllowThousands | NumberStyles.Integer);
                return actualValue;
            }
            catch (Exception)
            {
            }

            return null;
        }
        #endregion
    }
}