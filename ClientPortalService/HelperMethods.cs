using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Text.RegularExpressions;
using Martex.DMS.DAL.Entities;
using System.Text;

namespace ClientPortalService
{
    public static class HelperMethods
    {
        #region Validation Helper Methods
        private static bool ValidateRequiredStringWithInputLength(string message, int length)
        {
            bool isValid = true;
            if (string.IsNullOrEmpty(message) || message.Length > length)
            {
                isValid = false;
            }
            return isValid;
        }

        private static bool ValidateStringWithInputLength(string message, int length)
        {
            bool isValid = true;
            if (string.IsNullOrEmpty(message))
            {
                isValid = true;
            }

            if (!string.IsNullOrEmpty(message) && message.Length > length)
            {
                isValid = false;
            }
            return isValid;
        }

        private static bool IsValidEmail(string input)
        {
            return Regex.IsMatch(input, @"^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$");
        }

        private static bool IsLettersOnly(string input)
        {
            //TODO
                return true;
           
           // return Regex.IsMatch(input, @"^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$");
        }
        #endregion

        #region Supported Methods
        private static List<ValidationError> ValidateModel(MemberModel model,bool isUpdate = false)
        {
            List<ValidationError> list = new List<ValidationError>();

            #region Member ID
            if (isUpdate)
            {
                if (model.MemberID <= 0)
                {
                    list.Add(new ValidationError()
                    {
                        Key = "Member ID",
                        Message = "Member ID is Required"
                    });
                }
            }
            else
            {
                if (model.MemberID > 0)
                {
                    list.Add(new ValidationError()
                    {
                        Key = "Member ID",
                        Message = "Member ID is not Required or pass 0"
                    });
                }
            }
            #endregion

            #region First Name
            if (!ValidateRequiredStringWithInputLength(model.FirstName, 50) || !IsLettersOnly(model.FirstName))
            {
                list.Add(new ValidationError()
                {
                    Key = "First Name",
                    Message = "First Name accepts only letter and maximum letters allowed is 50"
                });
            }
            #endregion

            #region Middle Name
            if (!IsLettersOnly(model.MiddleName) || !(ValidateStringWithInputLength(model.MiddleName,50)))
            {
                list.Add(new ValidationError()
                {
                    Key = "Middle Name",
                    Message = "Middle Name accepts only letter and maximum letters allowed is 50"
                });
            }
            #endregion

            #region Last Name
            if (!ValidateRequiredStringWithInputLength(model.LastName, 50) || !IsLettersOnly(model.LastName))
            {
                list.Add(new ValidationError()
                {
                    Key = "Last Name",
                    Message = "Last Name accepts only letter and maximum letters allowed is 50"
                });
            }
            #endregion

            #region Address Line 1
            if (!ValidateRequiredStringWithInputLength(model.AddressLine1, 100))
            {
                list.Add(new ValidationError()
                {
                    Key = "Address Line 1",
                    Message = "Address Line 1 is Required and maximum length allowed is 100"
                });
            }
            #endregion
            
            #region Address Line 2
            if (!ValidateStringWithInputLength(model.AddressLine2, 100))
            {
                list.Add(new ValidationError()
                {
                    Key = "Address Line 2",
                    Message = "Address Line 2 maximum length allowed is 100"
                });
            }
            #endregion
            
            #region Address Line 3
            if (!ValidateStringWithInputLength(model.AddressLine3, 100))
            {
                list.Add(new ValidationError()
                {
                    Key = "Address Line 3",
                    Message = "Address Line 3 maximum length allowed is 100"
                });
            }
            #endregion

            #region Email
            if (!ValidateStringWithInputLength(model.Email, 50) && !IsValidEmail(model.Email))
            {
                list.Add(new ValidationError()
                {
                    Key = "Email",
                    Message = "Email length allowed is 50 should be proper format"
                });
            }

            
            #endregion

            #region City
            if (!(ValidateStringWithInputLength(model.City,100)))
            {
                list.Add(new ValidationError()
                {
                    Key = "City",
                    Message = "City is required maximum letters allowed is 100"
                });
            }
            #endregion

            #region Postal Code
            if (!(ValidateStringWithInputLength(model.PostalCode,10)))
            {
                list.Add(new ValidationError()
                {
                    Key = "Postal Code",
                    Message = "PostalCode maximum letters allowed is 10"
                });
            }
            #endregion

            #region Effective Date
            if(!model.EffectiveDate.HasValue || model.EffectiveDate.Value == DateTime.MinValue || model.EffectiveDate.Value < DateTime.Now)
            {
                list.Add(new ValidationError()
                {
                    Key = "Effective Date",
                    Message = "Effective Date is required and should be the future date"
                });
            }
            #endregion

            #region Expiration Date
            if(!model.ExpirationDate.HasValue || model.ExpirationDate.Value == DateTime.MinValue || model.ExpirationDate.Value < DateTime.Now || model.ExpirationDate <= model.EffectiveDate )
            {
                list.Add(new ValidationError()
                {
                    Key = "Expiration Date",
                    Message = "Expiration Date is required and should be the future date"
                });
            }
            #endregion

            #region Remove 0
            if (model.PhoneType.HasValue)
            {
                if (model.PhoneType.Value <= 0)
                {
                    list.Add(new ValidationError()
                    {
                        Key = "Phone Type",
                        Message = "Phone Type Value is not valid"
                    });
                }
            }
            else
            {
                list.Add(new ValidationError()
                {
                    Key = "Phone Type",
                    Message = "Phone Type Value is Required"
                });
            }

            if (model.AddressTypeID.HasValue)
            {
                if (model.AddressTypeID.Value <= 0)
                {
                    list.Add(new ValidationError()
                    {
                        Key = "Address Type",
                        Message = "Address Type Value is not valid"
                    });
                }
            }
            else
            {
                list.Add(new ValidationError()
                {
                    Key = "Address Type",
                    Message = "Address Type Value is Required"
                });
            }
            #endregion

            return list;
        }

        public static bool IsValid(this MemberModel model,bool isUpdate = false)
        {
            bool isValid = true;
            List<ValidationError> validationErrors = ValidateModel(model, isUpdate);
            if (validationErrors != null && validationErrors.Count > 0)
            {
                isValid = false;
            }
            return isValid;
        }
       
        public static List<ValidationError> ModelErrors(this MemberModel model)
        {
            List<ValidationError> validationErrors = ValidateModel(model);
            return validationErrors;
        }
        #endregion
    }


}