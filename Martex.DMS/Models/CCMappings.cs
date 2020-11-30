using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using CsvHelper.Configuration;
using Martex.DMS.BLL.Model.TempCCPModels;
using System.ComponentModel;
using CsvHelper.TypeConversion;

namespace Martex.DMS.Models
{
    public class VirtualPlusMap : CsvClassMap<VirtualPlus>
    {
        //http://joshclose.github.io/CsvHelper/
        //https://github.com/JoshClose/CsvHelper

        public override void CreateMap()
        {
            /*
             * KB (4/12): Updated the mapping as per the latest file format. 
             * Commented out the older mappings as those fields are no longer in use
             */
            Map(m => m.PurchaseId).Index(0).TypeConverter<StringConverter>();
            Map(m => m.CreateDate).Name("Request Date").TypeConverter<DateTimeConverter>();
            //Map(m => m.CorporateName).Name("CORPORATE_NAME").TypeConverter<StringConverter>();
            Map(m => m.UserName).Name("Requestor").TypeConverter<StringConverter>();
            Map(m => m.ActionType).Name("Purchase Request Status").TypeConverter<StringConverter>();
            //Map(m => m.PurchaseStatus).Name("PURCHASE_STATUS").TypeConverter<StringConverter>();
            Map(m => m.PurchaseType).Name("Purchase Type").TypeConverter<StringConverter>();
            //Map(m => m.RequestedAmount).Name("REQUESTED_AMOUNT").TypeConverter<DecimalConverter>();
            Map(m => m.ApprovedAmount).Name("Billing Amount").TypeConverter<DecimalConverter>();
            //Map(m => m.HistorialAvlBalance).Name("HISTORICAL_AVAILABLE_BALANCE").TypeConverter<DecimalConverter>();
            Map(m => m.VCardAlias).Name("Real Card Alias").TypeConverter<StringConverter>();
            //Map(m => m.CurrencyCode).Name("Billing Currency Code").TypeConverter<IntConverter>();
            //Map(m => m.JournalStatus).Name("JRNL_STATUS").TypeConverter<StringConverter>();
            //Map(m => m.HistoryID).Name("HISTORY_ID").TypeConverter<IntConverter>();
            Map(m => m.CpnPan).Name("Virtual Card Number").TypeConverter<StringConverter>();
            Map(m => m.AvailableBalance).Name("Available Balance").TypeConverter<DecimalConverter>();
            Map(m => m.CDF_ISP_Vendor).Name("CDF1 Value").TypeConverter<StringConverter>();
            Map(m => m.CDF_PO).Name("CDF2 Value").TypeConverter<StringConverter>();
        }
    }

    public class ChargedTransactionsMap : CsvClassMap<ChargedTransactions>
    {
        //http://joshclose.github.io/CsvHelper/
        //https://github.com/JoshClose/CsvHelper

        public override void CreateMap()
        {
            Map(m => m.AccountName).Name("ACC.ACCOUNT NAME");
            Map(m => m.AccountnNumber).Name("ACC.ACCOUNT NUMBER");
            Map(m => m.FinTransactionDate).Name("FIN.TRANSACTION DATE").TypeConverter<DateConverter>();
            Map(m => m.FinPostingDate).Name("FIN.POSTING DATE").TypeConverter<DateConverter>();
            Map(m => m.FinTransactionDescription).Name("FIN.TRANSACTION DESCRIPTION");
            Map(m => m.FinTransactionAmount).Name("FIN.TRANSACTION AMOUNT").TypeConverter<DecimalConverter>();
            Map(m => m.FinVirtualCardNumber).Name("FIN.VIRTUAL CARD NUMBER").TypeConverter<RemoveDoubleQuotesConverter>(); 
            Map(m => m.FinCFFDataFirst).Name("FIN.CFF.DATA 01"); 
            Map(m => m.FinCFFDataSecond).Name("FIN.CFF.DATA 02").TypeConverter<RemoveDoubleQuotesConverter>(); // Vendor Number
            Map(m => m.FinCFFDataThird).Name("FIN.CFF.DATA 03"); // PO Number

        }
    }

    #region Converters

    public class RemoveDoubleQuotesConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            if (text.Equals(DiscaredText))
            {
                return null;
            }
            else
            {
                string data = text.Replace("\"", "");
                if (string.IsNullOrEmpty(data))
                {
                    return null;
                }
                else
                {
                    return data;
                }
            }
        }

      
    }

    public class DateConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            DateTime result = DateTime.MinValue;
            try
            {
                if (text.Equals(DiscaredText))
                {
                    return result;
                }
                result = DateTime.ParseExact(text, "M/d/yyyy", new System.Globalization.CultureInfo("en-US"));
            }
            catch (FormatException fex)
            {
                string error = fex.Message;
                try
                {
                    result = DateTime.ParseExact(text, "M-d-yyyy", new System.Globalization.CultureInfo("en-US"));
                }
                catch (FormatException f)
                {
                    throw f;
                }
            }
            return result;
        }

        public override string ConvertToString(TypeConverterOptions options, object value)
        {
            return ((DateTime)value).ToString("M/d/yyyy");
        }
       
    }

    public class DateTimeConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            DateTime result = DateTime.MinValue;
            try
            {
                if (text.Equals(DiscaredText))
                {
                    return result;
                }
                result = DateTime.Parse(text);
            }
            catch (FormatException fex)
            {
                throw fex;
            }
            return result;
        }

        public override string ConvertToString(TypeConverterOptions options, object value)
        {
            return ((DateTime)value).ToLongDateString();
        }

    }

    public class DecimalConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            if (text.Equals(DiscaredText) || string.IsNullOrWhiteSpace(text))
            {
                return (decimal)0;
            }
            else
            {
                try
                {
                    string data = text.Replace(",", "");
                    decimal val = Convert.ToDecimal(text);
                    return val;
                }
                catch (Exception ex)
                {
                    
                    throw ex; 
                }
             
            }
        }
    }

    public class StringConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            if (text.Equals(DiscaredText))
            {
                return null;
            }
            else
            {
                return text;
            }
        }
    }

    public abstract class GenericConverter : ITypeConverter
    {
        public string DiscaredText = "##END##";

        public bool CanConvertFrom(Type type)
        {
            if (type == typeof(string))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public bool CanConvertTo(Type type)
        {
            if (type == typeof(string))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public abstract object ConvertFromString(TypeConverterOptions options, string text);
       
        public virtual string ConvertToString(TypeConverterOptions options, object value)
        {
            try
            {
                return value.ToString();
            }
            catch (Exception ex)
            {
                
                throw ex;
            }
           
        }
    }

    public class IntConverter : GenericConverter
    {
        public override object ConvertFromString(TypeConverterOptions options, string text)
        {
            if (text.Equals(DiscaredText))
            {
                return 0;
            }
            else
            {
                return Convert.ToInt32(text);
            }
        }

        public override string ConvertToString(TypeConverterOptions options, object value)
        {
            return ((int)value).ToString();
        }
    }

    #endregion

    
}
