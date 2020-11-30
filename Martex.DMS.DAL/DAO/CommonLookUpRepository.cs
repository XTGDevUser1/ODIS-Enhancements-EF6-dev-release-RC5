using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{

    /// <summary>
    /// 
    /// </summary>
    public class CommonLookUpRepository
    {

        /// <summary>
        /// Gets the billing invoice detail status.
        /// </summary>
        /// <param name="statusID">The status ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public BillingInvoiceDetailStatu GetBillingInvoiceDetailStatus(int statusID)
        {
            BillingInvoiceDetailStatu model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.BillingInvoiceDetailStatus.Where(u => u.ID == statusID && u.IsActive == true).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Details for BillingInvoiceDetailStatus {0}", statusID));
            }
            return model;
        }

        /// <summary>
        /// Gets the billing adjustment reason.
        /// </summary>
        /// <param name="reasonID">The reason ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public BillingAdjustmentReason GetBillingAdjustmentReason(int reasonID)
        {
            BillingAdjustmentReason model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.BillingAdjustmentReasons.Where(u => u.ID == reasonID && u.IsActive == true).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Details for BillingAdjustmentReason {0}", reasonID));
            }
            return model;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <returns></returns>
        public NextAction GetNextAction(int recordID)
        {
            NextAction model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.NextActions.Include("ServiceRequestPriority").Where(u => u.ID == recordID).FirstOrDefault();
            }
            //if (model == null)
            //{
            //    throw new DMSException(string.Format("Unable to retrieve Next Action {0}", recordID));
            //}
            return model;
        }

        public NextAction GetNextActionByName(string nextActionName)
        {
            NextAction model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.NextActions.Include("ServiceRequestPriority").Where(u => u.Name == nextActionName).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <returns></returns>
        public List<NextActionRole> GetNextActionRoles(int recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.NextActionRoles.Where(u => u.NextActionID == recordID).ToList();
            }
        }
        
        /// <summary>
        /// Gets the billing exclude reason.
        /// </summary>
        /// <param name="reasonID">The reason ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public BillingExcludeReason GetBillingExcludeReason(int reasonID)
        {
            BillingExcludeReason model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.BillingExcludeReasons.Where(u => u.ID == reasonID && u.IsActive == true).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Details for Billing Exclude Reason {0}", reasonID));
            }
            return model;
        }
        /// <summary>
        /// Gets the vendor region by state ID.
        /// </summary>
        /// <param name="stateID">The state ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public VendorRegion GetVendorRegionByStateID(int stateID)
        {
            VendorRegion model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = (from regionState in dbContext.VendorRegionStateProvinces
                         join vendorRegion in dbContext.VendorRegions
                         on regionState.VendorRegionID equals vendorRegion.ID
                         where regionState.StateProvinceID == stateID
                         select vendorRegion).FirstOrDefault();

            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Vendor Region for given State ID {0}", stateID));
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor region by ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public VendorRegion GetVendorRegionByID(int recordID)
        {
            VendorRegion model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.VendorRegions.Where(u => u.ID == recordID).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Vendor Region for given ID {0}", recordID));
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor status.
        /// </summary>
        /// <param name="statusID">The status ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public VendorLocationStatu GetVendorLocationStatus(int statusID)
        {
            VendorLocationStatu status = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                status = dbContext.VendorLocationStatus.Where(u => u.ID == statusID).FirstOrDefault();
            }
            if (status == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Vendor Location Status for given ID {0}", statusID));
            }
            return status;

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public VehicleType GetVehicleTypeByName(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VehicleTypes.Where(u => u.Name.Equals(name)).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the country.
        /// </summary>
        /// <param name="countryId">The country id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the country</exception>
        public Country GetCountry(int countryId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                Country country = entities.Countries.Where(id => id.ID == countryId).FirstOrDefault();
                if (country == null)
                {
                    throw new DMSException("Unable to retrieve details for the country");
                }
                return country;
            }
        }

        /// <summary>
        /// Gets the payment reason.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public PaymentReason GetPaymentReason(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PaymentReasons.Where(u => u.ID == id).FirstOrDefault();
            }
        }

        public List<PaymentReason> GetPaymentReasonsByName(string paymentReason)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PaymentReasons.Where(a => a.Name.Equals(paymentReason, StringComparison.InvariantCultureIgnoreCase)).ToList();
            }
        }

        /// <summary>
        /// Gets the payment status by ID.
        /// </summary>
        /// <param name="paymentStatusID">The payment status ID.</param>
        /// <returns></returns>
        public string GetPaymentStatusByID(int paymentStatusID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                PaymentStatu paymentStatus = entities.PaymentStatus.Where(id => id.ID == paymentStatusID).FirstOrDefault();
                if (paymentStatus != null)
                {
                    return paymentStatus.Name;
                }
                return string.Empty;
            }
        }
        /// <summary>
        /// Gets the type of the payment.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public PaymentType GetPaymentType(int id)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                PaymentType type = entities.PaymentTypes.Where(u => u.ID == id).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve payment type ID {0}", id));
                }
                return type;
            }
        }
        /// <summary>
        /// Gets the type of the payment.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public PaymentType GetPaymentType(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                PaymentType type = entities.PaymentTypes.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve payment type Name {0}", name));
                }
                return type;
            }
        }
        /// <summary>
        /// Gets the type of the claim.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ClaimType GetClaimType(int id)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ClaimType type = entities.ClaimTypes.Where(u => u.ID == id).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Claim type ID {0}", id));
                }
                return type;
            }
        }
        /// <summary>
        /// Gets the claim status.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ClaimStatu GetClaimStatus(int id)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ClaimStatu type = entities.ClaimStatus.Where(u => u.ID == id).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Claim Status ID {0}", id));
                }
                return type;
            }
        }
        public ClaimStatu GetClaimStatus(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ClaimStatu type = entities.ClaimStatus.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Claim Status Name {0}", name));
                }
                return type;
            }
        }

        /// <summary>
        /// Gets the ACH status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ACHStatu GetACHStatus(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ACHStatu type = entities.ACHStatus.Where(u => u.Name.Equals(name)).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve ACH Status Name {0}", name));
                }
                return type;
            }
        }


        /// <summary>
        /// Gets the aces claim status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ACESClaimStatu GetACESClaimStatus(int id)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ACESClaimStatu type = entities.ACESClaimStatus.Where(u => u.ID == id).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve ACS Claim Status ID {0}", id));
                }
                return type;
            }
        }

        public ACESClaimStatu GetACESClaimStatus(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ACESClaimStatu type = entities.ACESClaimStatus.Where(u => u.Name.Equals(name)).FirstOrDefault();
                if (type == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve ACS Claim Status Name {0}", name));
                }
                return type;
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public AccessType GetAccessType(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.AccessTypes.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the contact category.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactCategory GetContactCategory(string name)
        {
            ContactCategory model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ContactCategories.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the contact reason.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <param name="contactCategoryID">The contact category ID.</param>
        /// <returns></returns>
        public ContactReason GetContactReason(string name, int contactCategoryID)
        {
            ContactReason model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ContactReasons.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && u.ContactCategoryID == contactCategoryID).FirstOrDefault();
            }
            return model;
        }
        /// <summary>
        /// Gets the contact reason.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <param name="contactCategoryID">The contact category ID.</param>
        /// <returns></returns>
        public ContactAction GetContactAction(string name, int contactCategoryID)
        {
            ContactAction model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ContactActions.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && u.ContactCategoryID == contactCategoryID).FirstOrDefault();
            }
            return model;
        }
        /// <summary>
        /// Gets the type of the contact.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactType GetContactType(string name)
        {
            ContactType model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ContactTypes.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
            return model;
        }
        /// <summary>
        /// Gets the contact method.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContactMethod GetContactMethod(string name)
        {
            ContactMethod model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.ContactMethods.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Contact Method Name {0}", name));
            }
            return model;
        }

        /// <summary>
        /// Gets the type of the payment transaction.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public int? GetPaymentTransactionType(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                PaymentTransactionType transactionType = entities.PaymentTransactionTypes.Where(u => u.Name.Equals(name)).FirstOrDefault();
                if (transactionType == null)
                {
                    return null;
                }

                return transactionType.ID;
            }
        }

        /// <summary>
        /// Gets the payment status.
        /// </summary>
        /// <param name="status">The status.</param>
        /// <returns></returns>
        public int? GetPaymentStatus(string status)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                PaymentStatu paymentStatus = entities.PaymentStatus.Where(id => id.Name.Equals(status)).FirstOrDefault();
                if (paymentStatus != null)
                {
                    return paymentStatus.ID;
                }
                paymentStatus = entities.PaymentStatus.Where(n => n.Name.Equals("Unknown")).FirstOrDefault();
                if (paymentStatus != null)
                {
                    return paymentStatus.ID;
                }

                return null;
            }
        }

        /// <summary>
        /// Gets the name of the country by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Country GetCountryByName(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                Country country = entities.Countries.Where(c => c.Name == name).FirstOrDefault();

                return country;
            }
        }

        /// <summary>
        /// Gets the country by code.
        /// </summary>
        /// <param name="code">The code.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public Country GetCountryByCode(string code)
        {
            Country country = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                country = dbContext.Countries.Where(c => c.ISOCode == code).FirstOrDefault();
            }
            //if (country == null)
            //{
            //    throw new DMSException(string.Format("Unable to retrieve Country with code : {0}", code));
            //}
            return country;
        }

        /// <summary>
        /// Gets the state province.
        /// </summary>
        /// <param name="stateId">The state id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the State</exception>
        public StateProvince GetStateProvince(int stateId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                StateProvince state = entities.StateProvinces.Where(id => id.ID == stateId).FirstOrDefault();
                if (state == null)
                {
                    throw new DMSException("Unable to retrieve details for the State");
                }
                return state;
            }
        }

        /// <summary>
        /// Gets the state province by abbreviation.
        /// </summary>
        /// <param name="abbr">The abbr.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the State</exception>
        public StateProvince GetStateProvinceByAbbreviation(string abbr)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                StateProvince state = entities.StateProvinces.Include("Country").Where(id => id.Abbreviation.Equals(abbr)).FirstOrDefault();
                if (state == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve details for the State : {0}",abbr));
                }
                return state;
            }
        }

        /// <summary>
        /// Gets the suffix.
        /// </summary>
        /// <param name="suffixId">The suffix id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the Suffix</exception>
        public Suffix GetSuffix(int suffixId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                Suffix suffix = entities.Suffixes.Where(id => id.ID == suffixId).FirstOrDefault();
                if (suffix == null)
                {
                    throw new DMSException("Unable to retrieve details for the Suffix");
                }
                return suffix;
            }
        }
        /// <summary>
        /// Gets the suffix.
        /// </summary>
        /// <param name="suffixId">The suffix id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the Suffix</exception>
        public Suffix GetSuffix(string suffixId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                Suffix suffix = entities.Suffixes.Where(u => u.Name.Equals(suffixId, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                if (suffix == null)
                {
                    throw new DMSException("Unable to retrieve details for the Suffix");
                }
                return suffix;
            }
        }

        /// <summary>
        /// Gets the prefix.
        /// </summary>
        /// <param name="prefixId">The prefix id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the Prefix</exception>
        public Prefix GetPrefix(int prefixId)
        {
            Prefix prefix = null;
            using (DMSEntities entities = new DMSEntities())
            {
                prefix = entities.Prefixes.Where(id => id.ID == prefixId).FirstOrDefault();
            }
            return prefix;

        }

        /// <summary>
        /// Gets the program.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public Program GetProgram(int programID)
        {
            Program program = null;
            using (DMSEntities entities = new DMSEntities())
            {
                program = entities.Programs.Where(id => id.ID == programID).FirstOrDefault();
            }
            return program;

        }

        /// <summary>
        /// Gets the source system.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public SourceSystem GetSourceSystem(string name)
        {
            SourceSystem source = null;
            using (DMSEntities entities = new DMSEntities())
            {
                source = entities.SourceSystems.Where(n => n.Name.Equals(name, StringComparison.Ordinal)).FirstOrDefault();
            }
            if (source == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Source System Name {0}", name));
            }
            return source;
        }

        /// <summary>
        /// Gets the source system.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public SourceSystem GetSourceSystem(int id)
        {
            SourceSystem source = null;
            using (DMSEntities entities = new DMSEntities())
            {
                source = entities.SourceSystems.Where(u => u.ID == id).FirstOrDefault();
            }
            if (source == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Source System ID {0}", id));
            }
            return source;
        }

        /// <summary>
        /// Gets the event.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public Event GetEvent(string name)
        {
            Event model = null;
            using (DMSEntities entities = new DMSEntities())
            {
                model = entities.Events.Where(n => n.Name.Equals(name, StringComparison.Ordinal)).FirstOrDefault();
            }
            if (model == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Event {0}", name));
            }
            return model;

        }

        /// <summary>
        /// Gets the prefix.
        /// </summary>
        /// <param name="prefixId">The prefix id.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve details for the Prefix</exception>
        public Prefix GetPrefix(string name)
        {
            Prefix prefix = null;
            using (DMSEntities entities = new DMSEntities())
            {
                prefix = entities.Prefixes.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
            return prefix;
        }

        /// <summary>
        /// Gets the name of the address type by.
        /// </summary>
        /// <param name="addressTypeName">Name of the address type.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public AddressType GetAddressTypeByName(string addressTypeName)
        {
            AddressType addressType = null;
            using (DMSEntities entities = new DMSEntities())
            {
                addressType = entities.AddressTypes.Where(u => u.Name == addressTypeName).FirstOrDefault();
            }
            if (addressType == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Address Type {0}", addressTypeName));
            }
            return addressType;
        }

        /// <summary>
        /// Gets the name of the phone type by.
        /// </summary>
        /// <param name="phoneTypeName">Name of the phone type.</param>
        /// <returns></returns>
        public PhoneType GetPhoneTypeByName(string phoneTypeName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.PhoneTypes.Where(a => a.Name == phoneTypeName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the vehicle category by.
        /// </summary>
        /// <param name="vehicleCategoryName">Name of the vehicle category.</param>
        /// <returns></returns>
        public VehicleCategory GetVehicleCategoryByName(string vehicleCategoryName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.VehicleCategories.Where(a => a.Name == vehicleCategoryName).FirstOrDefault();
            }
        }
    }
}
