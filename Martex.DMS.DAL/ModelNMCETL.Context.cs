﻿//------------------------------------------------------------------------------
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
    using System.Data.Entity;
    using System.Data.Entity.Infrastructure;
    using System.Data.Entity.Core.Objects;
    using System.Linq;
    
    public partial class NMC_ETLEntities : DbContext
    {
        public NMC_ETLEntities()
            : base("name=NMC_ETLEntities")
        {
        }
    
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            throw new UnintentionalCodeFirstException();
        }
    
        public virtual DbSet<ExecutionLog> ExecutionLogs { get; set; }
        public virtual DbSet<APCheckRequest> APCheckRequests { get; set; }
        public virtual DbSet<APVendorMaster> APVendorMasters { get; set; }
        public virtual DbSet<InvoiceRequest> InvoiceRequests { get; set; }
    
        public virtual int CreateExecutionLog(string description, string userName, ObjectParameter logID)
        {
            var descriptionParameter = description != null ?
                new ObjectParameter("Description", description) :
                new ObjectParameter("Description", typeof(string));
    
            var userNameParameter = userName != null ?
                new ObjectParameter("UserName", userName) :
                new ObjectParameter("UserName", typeof(string));
    
            return ((IObjectContextAdapter)this).ObjectContext.ExecuteFunction("CreateExecutionLog", descriptionParameter, userNameParameter, logID);
        }
    
        public virtual int UpdateExecutionLog(Nullable<int> logID, Nullable<int> status)
        {
            var logIDParameter = logID.HasValue ?
                new ObjectParameter("LogID", logID) :
                new ObjectParameter("LogID", typeof(int));
    
            var statusParameter = status.HasValue ?
                new ObjectParameter("Status", status) :
                new ObjectParameter("Status", typeof(int));
    
            return ((IObjectContextAdapter)this).ObjectContext.ExecuteFunction("UpdateExecutionLog", logIDParameter, statusParameter);
        }
    
        public virtual int UpdateStatusOnStagingTables(Nullable<long> etlExecutionLogID)
        {
            var etlExecutionLogIDParameter = etlExecutionLogID.HasValue ?
                new ObjectParameter("etlExecutionLogID", etlExecutionLogID) :
                new ObjectParameter("etlExecutionLogID", typeof(long));
    
            return ((IObjectContextAdapter)this).ObjectContext.ExecuteFunction("UpdateStatusOnStagingTables", etlExecutionLogIDParameter);
        }
    
        public virtual int UpdateStatusOnInvoiceRequest(Nullable<long> etlExecutionLogID)
        {
            var etlExecutionLogIDParameter = etlExecutionLogID.HasValue ?
                new ObjectParameter("etlExecutionLogID", etlExecutionLogID) :
                new ObjectParameter("etlExecutionLogID", typeof(long));
    
            return ((IObjectContextAdapter)this).ObjectContext.ExecuteFunction("UpdateStatusOnInvoiceRequest", etlExecutionLogIDParameter);
        }
    
        public virtual int UpdateExecutionLogForBilling(Nullable<int> logID, Nullable<int> status)
        {
            var logIDParameter = logID.HasValue ?
                new ObjectParameter("LogID", logID) :
                new ObjectParameter("LogID", typeof(int));
    
            var statusParameter = status.HasValue ?
                new ObjectParameter("Status", status) :
                new ObjectParameter("Status", typeof(int));
    
            return ((IObjectContextAdapter)this).ObjectContext.ExecuteFunction("UpdateExecutionLogForBilling", logIDParameter, statusParameter);
        }
    }
}