//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.DAL
{
    using System;
    using System.Collections.Generic;
    
    [Serializable] 
    public partial class Client
    {
    	public Client()
        {
            this.BillingDefinitionInvoices = new HashSet<BillingDefinitionInvoice>();
            this.BillingInvoices = new HashSet<BillingInvoice>();
            this.ClientChangeLogMappings = new HashSet<ClientChangeLogMapping>();
            this.OrganizationClients = new HashSet<OrganizationClient>();
            this.Programs = new HashSet<Program>();
            this.ClientUsers = new HashSet<ClientUser>();
            this.UserInvites = new HashSet<UserInvite>();
            this.Feedbacks = new HashSet<Feedback>();
            this.Vendors = new HashSet<Vendor>();
            this.ClientToCompanyMaps = new HashSet<ClientToCompanyMap>();
            this.AccessControlLists = new HashSet<AccessControlList>();
            this.ClientRoles = new HashSet<ClientRole>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string AccountingSystemCustomerNumber { get; set; }
        public string AccountingSystemAddressCode { get; set; }
        public Nullable<decimal> PaymentBalance { get; set; }
        public Nullable<decimal> AccountingSystemDivisionCode { get; set; }
        public Nullable<int> ClientTypeID { get; set; }
        public string Website { get; set; }
        public string MainContactFirstName { get; set; }
        public string MainContactLastName { get; set; }
        public string MainContactPhone { get; set; }
        public string MainContactEmail { get; set; }
        public Nullable<int> ClientRepID { get; set; }
        public string FTPFolder { get; set; }
        public string Avatar { get; set; }
    
        public virtual ICollection<BillingDefinitionInvoice> BillingDefinitionInvoices { get; set; }
        public virtual ICollection<BillingInvoice> BillingInvoices { get; set; }
        public virtual ICollection<ClientChangeLogMapping> ClientChangeLogMappings { get; set; }
        public virtual ICollection<OrganizationClient> OrganizationClients { get; set; }
        public virtual ICollection<Program> Programs { get; set; }
        public virtual ClientType ClientType { get; set; }
        public virtual ICollection<ClientUser> ClientUsers { get; set; }
        public virtual ICollection<UserInvite> UserInvites { get; set; }
        public virtual ICollection<Feedback> Feedbacks { get; set; }
        public virtual ICollection<Vendor> Vendors { get; set; }
        public virtual ICollection<ClientToCompanyMap> ClientToCompanyMaps { get; set; }
        public virtual ICollection<AccessControlList> AccessControlLists { get; set; }
        public virtual ICollection<ClientRole> ClientRoles { get; set; }
        public virtual ClientRep ClientRep { get; set; }
    }
}
