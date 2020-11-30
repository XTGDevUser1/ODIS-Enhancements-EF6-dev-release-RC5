using System.Web.Http;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using log4net;
using Martex.DMS.DAL.Entities;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Facade;
using Newtonsoft.Json;
using System.Linq;

namespace ODISAPI.Controllers
{
    [RoutePrefix("api")]
    public class RoadsideServicesController : BaseApiController
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(RoadsideServicesController));

        /// <summary>
        /// Gets all roadside services for the given programID.
        /// </summary>
        /// <param name="id">The program identifier.</param>
        /// <returns>List of ProgramServices</returns>
        [Authorize]
        [Route("v1/RoadsideServices/{id}")]
        public OperationResult Get(int id)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("GET Roadside services for Program {0}", id);
            LogAPIEvent(EventNames.API_GET_ROADSIDE_SERVICES_BEGIN, new { ProgramID = id});
            var repository = new ProgramMaintenanceRepository();
            var list = repository.GetRoadsideServices(id);
            result.Data = list;
            LogAPIEvent(EventNames.API_GET_ROADSIDE_SERVICES_END, new { ProgramID = id});
            return result;
        }

        [Authorize]
        [Route("v1/RoadsideServices/Questions")]
        public OperationResult Get([FromUri] QuestionsCriteria criteria)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("GET questions for Roadside Service {0}", JsonConvert.SerializeObject(new
            {
                QuestionsCriteria = criteria
            }));
            LogAPIEvent(EventNames.API_GET_ROADSIDE_SERVICES_QUESTIONS_BEGIN, criteria);

            if (ModelState.IsValid)
            {
                // Get  IDs for the names.
                var productCategory = ReferenceDataRepository.GetProductCategoryByName(criteria.ProductCategory);
                ThrowExceptionIfNull(productCategory, string.Format("Invalid product category {0}", criteria.ProductCategory));

                var vehicleCategory = ReferenceDataRepository.GetVehicleCategoryByName(criteria.VehicleCategory);
                ThrowExceptionIfNull(vehicleCategory, string.Format("Invalid vehicle category {0}", criteria.VehicleCategory));

                var vehicleType = ReferenceDataRepository.GetVehicleTypeByName(criteria.VehicleType);
                ThrowExceptionIfNull(vehicleType, string.Format("Invalid vehicle type {0}", criteria.VehicleType));

                var sourceSystem = ReferenceDataRepository.GetSourceSystemByName(criteria.SourceSystem);
                ThrowExceptionIfNull(sourceSystem, string.Format("Invalid source system {0}", criteria.SourceSystem));

                var serviceFacade = new ServiceFacade();
                var questionnaire = serviceFacade.GetQuestionnaire(criteria.ProgramID, vehicleCategory.ID, vehicleType.ID, null, sourceSystem.Name);

                result.Data = questionnaire.Where(x=>x.ProductCategoryID == productCategory.ID).ToList();
            }
            else
            {
                result.Status = OperationStatus.ERROR;
                StringBuilder sb = new StringBuilder();
                foreach (var modelState in ModelState.Values)
                {
                    foreach (var error in modelState.Errors)
                    {
                        if (error.ErrorMessage != null)
                        {
                            sb.AppendLine(error.ErrorMessage.ToString());
                        }
                        if (error.Exception != null)
                        {
                            sb.AppendLine(error.Exception.ToString());
                        }
                    }
                }
                result.ErrorMessage = sb.ToString();
            }
            LogAPIEvent(EventNames.API_GET_ROADSIDE_SERVICES_QUESTIONS_END, criteria);
            return result;
        }
    }
}