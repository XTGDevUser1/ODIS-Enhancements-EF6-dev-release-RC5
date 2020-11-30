using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public partial class ClaimsFacade
    {

        public ClaimInformationModel GetServiceDetails(int claimID)
        {
            ClaimInformationModel model = new ClaimInformationModel();

            model.Claim = new DAL.Claim();
            model.Claim.ID = claimID;

            // Populate Previous Comments and Diagnostic codes.
            CommentRepository commentRepository = new CommentRepository();
            List<Comment> previousComments = commentRepository.Get(claimID, EntityNames.CLAIM);
            model.PreviousComments = previousComments;

            model.DiagnosticCodes = GetDiagnosticCodes(claimID);

            return model;

        }

        public List<ServiceDiagnosticCodeModel> GetDiagnosticCodes(int claimID)
        {
            return repository.GetDiagnosticCodes(claimID);
        }

        public List<DiagnosticCodes_Result> GetDiagnosticCodes(int claimID, int vehicleTypeID, string codeType)
        {
            return repository.GetDiagnosticCodes(claimID,vehicleTypeID,codeType);
        }

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
            repository.SaveDiagnosticCodes(claimID, selectedCodes, codeType, primaryCode, createBy);
        }
    }
}
