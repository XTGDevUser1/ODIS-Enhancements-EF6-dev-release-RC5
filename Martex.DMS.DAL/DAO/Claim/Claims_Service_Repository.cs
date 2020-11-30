using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;

namespace Martex.DMS.DAL.DAO
{
    public partial class ClaimsRepository
    {
        /// <summary>
        /// Saves the diagnostic codes.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <param name="selectedCodes">The selected codes.</param>
        /// <param name="codeType">Type of the code.</param>
        /// <param name="primaryCode">The primary code.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveDiagnosticCodes(int claimID, string selectedCodes, string codeType, int? primaryCode, string createBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveClaimDiagnosticCodes(claimID, selectedCodes, codeType, primaryCode, createBy);
            }
        }

        /// <summary>
        /// Gets the code types.
        /// </summary>
        /// <returns></returns>
        public Dictionary<string, string> GetCodeTypes()
        {
            Dictionary<string, string> list = new Dictionary<string, string>();
            list.Add("Ford Claim", "Ford Claim");

            return list;
        }

        /// <summary>
        /// Gets the diagnostic codes.
        /// </summary>
        /// <param name="claimID">The claim unique identifier.</param>
        /// <param name="vehicleTypeID">The vehicle type unique identifier.</param>
        /// <param name="codeType">Type of the code.</param>
        /// <returns></returns>
        public List<DiagnosticCodes_Result> GetDiagnosticCodes(int claimID, int vehicleTypeID, string codeType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetClaimDiagnosticCodes(claimID, vehicleTypeID, codeType);
                return result.ToList<DiagnosticCodes_Result>();
            }
        }

        public List<ServiceDiagnosticCodeModel> GetDiagnosticCodes(int claimID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from c in dbContext.ClaimVehicleDiagnosticCodes
                              join vdc in dbContext.VehicleDiagnosticCodes on c.VehicleDiagnosticCodeID equals vdc.ID
                              join vdcat in dbContext.VehicleDiagnosticCategories on vdc.VehicleDiagnosticCategoryID equals vdcat.ID
                              where c.ClaimID == claimID
                              orderby vdcat.Sequence, vdc.Sequence
                              select new ServiceDiagnosticCodeModel()
                              {
                                  ID = vdc.ID,
                                  CategoryName = vdcat.Name,
                                  IsPrimary = c.IsPrimary ?? false,
                                  Code = (c.VehicleDiagnosticCodeType == "Ford Claim" ? vdc.FordClaimCode : string.Empty
                                         ),
                                  CodeName = vdc.Name
                              }).ToList<ServiceDiagnosticCodeModel>();

                return result;
            }
        }

    }
}
