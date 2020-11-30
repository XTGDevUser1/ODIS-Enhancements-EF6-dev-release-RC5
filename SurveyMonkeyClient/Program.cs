using SurveyMonkey;
using SurveyMonkey.ProcessedAnswers;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SurveyMonkeyClient
{
    class SurveyResponse
    {
        public long EventLogID { get; set; }
        public long SurveyID { get; set; }
        public int? HowLikelyToRecommend { get; set; }
        public string RecommendComments { get; set; }
        public string PhoneAgentRating { get; set; }
        public string RVTechRating { get; set; }
        public string ServiceProviderRating { get; set; }
        public string AdditionalComments { get; set; }
        public bool PublishingApproval { get; set; }
        public long SurveyResponseID { get; set; }

        public SurveyResponse()
        {
            PublishingApproval = true;
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();

            sb.AppendFormat("EventLog ID : {0}, Survey ID : {1}, Survey Response ID: {2}", EventLogID, SurveyID, SurveyResponseID);
            sb.AppendLine();

            sb.AppendFormat("How likely to recommend ? {0}", HowLikelyToRecommend);
            sb.AppendLine();

            sb.AppendFormat("Recommendation comments: {0}", RecommendComments);
            sb.AppendLine();

            sb.AppendFormat("Phone Agent Rating: {0}", PhoneAgentRating);
            sb.AppendLine();

            sb.AppendFormat("RV Tech rating: {0}", RVTechRating);
            sb.AppendLine();

            sb.AppendFormat("Service Provider Rating: {0}", ServiceProviderRating);
            sb.AppendLine();

            sb.AppendFormat("Additional Comments: {0}", AdditionalComments);
            sb.AppendLine();

            sb.AppendFormat("Publishing Approval? {0}", PublishingApproval);
            sb.AppendLine();

            return sb.ToString();
        }

    }

    class Program
    {
        /* QuestionIDs */
        static readonly long Q_HowLikelyToRecommend = 0;
        static readonly long Q_RecommendComments = 0;
        static readonly long Q_PhoneAgentRating = 0;
        static readonly long Q_RVTechRating = 0;
        static readonly long Q_ServiceProviderRating = 0;
        static readonly long Q_AdditionalComments = 0;
        static readonly long Q_PublishingApproval = 0;

        static string query = "INSERT INTO SurveyResponse ([ELOGID], [SurveyID], [HowLikelyToRecommend], [RecommendComments], [PhoneAgentRating], [RVTechRating], [ServiceProviderRating], [AdditionalComments], [PublishingApproval], [DateCreated], [SurveyMonkeyResponseID]) VALUES (@elogid, @surveyID, @howLikelyToRecommend, @comments, @phoneAgentRating, @rvTechRating, @serviceProviderRating, @additionalComments, @publishingApproval, @dateCreated, @surveyMonkeyResponseID)";

        /* SM Settings */
        static string accessToken = string.Empty;
        static string surveyId = string.Empty;
        //static long collectorId = 167611254;
        static Program()
        {
            surveyId = ConfigurationManager.AppSettings["surveyId"];
            accessToken = ConfigurationManager.AppSettings["accessToken"];

            Q_HowLikelyToRecommend = long.Parse(ConfigurationManager.AppSettings["Q_HowLikelyToRecommend"]);
            Q_RecommendComments = long.Parse(ConfigurationManager.AppSettings["Q_RecommendComments"]);
            Q_PhoneAgentRating = long.Parse(ConfigurationManager.AppSettings["Q_PhoneAgentRating"]);
            Q_RVTechRating = long.Parse(ConfigurationManager.AppSettings["Q_RVTechRating"]);
            Q_ServiceProviderRating = long.Parse(ConfigurationManager.AppSettings["Q_ServiceProviderRating"]);
            Q_AdditionalComments = long.Parse(ConfigurationManager.AppSettings["Q_AdditionalComments"]);
            Q_PublishingApproval = long.Parse(ConfigurationManager.AppSettings["Q_PublishingApproval"]);
        }

        static void Main(string[] args)
        {
            var latestSurveyResponseID = GetLatestSurveyResponseID();
            using (var apiClient = new SurveyMonkeyApi(accessToken))
            {
                //var surveyResponses = apiClient.GetCollectorResponseOverviewList(collectorId);
                var populatedSurveys = apiClient.PopulateSurveyResponseInformation(long.Parse(surveyId));

                //Console.WriteLine("Survey :: {0}", populatedSurveys.Title);
                var surveyResponse = (SurveyResponse)null;

                populatedSurveys.Responses.ForEach(response =>
                {
                    if (response.CustomVariables != null && response.CustomVariables.ContainsKey("elogid"))
                    {
                        // Reset object
                        surveyResponse = new SurveyResponse() { EventLogID = long.Parse(response.CustomVariables["elogid"]), SurveyResponseID = response.Id.GetValueOrDefault(), SurveyID = long.Parse(surveyId) };

                        response.Questions.ForEach(question =>
                        {

                            //Console.WriteLine("Q: [{0}] {1}", question.Id, question.ProcessedAnswer.QuestionHeading);
                            var processedResponse = question.ProcessedAnswer.Response;
                            if (processedResponse is OpenEndedSingleAnswer)
                            {
                                FillSurveyResponse(question.Id, ((OpenEndedSingleAnswer)processedResponse).Text, surveyResponse);
                            }
                            else if (processedResponse is MatrixRatingAnswer)
                            {
                                FillSurveyResponse(question.Id, ((MatrixRatingAnswer)processedResponse).Rows[0].Choice, surveyResponse);
                            }
                            else if (processedResponse is MatrixSingleAnswer)
                            {
                                var matrixSingleAnswerQuestions = processedResponse as MatrixSingleAnswer;
                                int index = 0;
                                matrixSingleAnswerQuestions.Rows.ForEach(msaq =>
                                {
                                    FillSurveyResponse(question.Answers[index].RowId, msaq.Choice, surveyResponse);
                                    index++;
                                });
                            }
                            else if (processedResponse is MultipleChoiceAnswer)
                            {
                                FillSurveyResponse(question.Id, ((MultipleChoiceAnswer)processedResponse).Choices[0], surveyResponse);
                            }
                            //Console.WriteLine();
                        });

                        //Console.WriteLine(surveyResponse);

                        // Process if only the response ID is greater than max we already have stored in previous iteration
                        if (surveyResponse.SurveyResponseID > latestSurveyResponseID)
                        {
                            DumpResponse(surveyResponse);
                            latestSurveyResponseID = surveyResponse.SurveyResponseID;
                        }
                    }
                });
            }

        }

        private static void AddParameterToCommand(string parameterName, System.Data.SqlDbType sqlType, object value, SqlCommand sqlCommand)
        {
            var sqlParameter = new SqlParameter(parameterName, sqlType);
            sqlParameter.Value = value;
            sqlCommand.Parameters.Add(sqlParameter);
        }

        private static long GetLatestSurveyResponseID()
        {
            long latestSurveyResponseID = 0;

            using (var sqlConnection = new SqlConnection(ConfigurationManager.ConnectionStrings["ApplicationServices"].ConnectionString))
            {
                var sqlCommand = new SqlCommand("SELECT ISNULL(MAX(SurveyMonkeyResponseID),0) FROM SurveyResponse", sqlConnection);
                sqlConnection.Open();
                latestSurveyResponseID = (long)sqlCommand.ExecuteScalar();
            }

            return latestSurveyResponseID;
        }

        private static void DumpResponse(SurveyResponse surveyResponse)
        {
            Console.WriteLine("Saving ....");
            Console.WriteLine(surveyResponse);
            using (var sqlConnection = new SqlConnection(ConfigurationManager.ConnectionStrings["ApplicationServices"].ConnectionString))
            {
                var sqlCommand = new SqlCommand(query, sqlConnection);

                AddParameterToCommand("@elogid", System.Data.SqlDbType.BigInt, surveyResponse.EventLogID, sqlCommand);
                AddParameterToCommand("@surveyID", System.Data.SqlDbType.BigInt, surveyResponse.SurveyID, sqlCommand);
                AddParameterToCommand("@howLikelyToRecommend", System.Data.SqlDbType.Int, surveyResponse.HowLikelyToRecommend, sqlCommand);
                AddParameterToCommand("@comments", System.Data.SqlDbType.NText, surveyResponse.RecommendComments, sqlCommand);
                AddParameterToCommand("@phoneAgentRating", System.Data.SqlDbType.NText, surveyResponse.PhoneAgentRating, sqlCommand);
                AddParameterToCommand("@rvTechRating", System.Data.SqlDbType.NText, surveyResponse.RVTechRating, sqlCommand);
                AddParameterToCommand("@serviceProviderRating", System.Data.SqlDbType.NText, surveyResponse.ServiceProviderRating, sqlCommand);
                AddParameterToCommand("@additionalComments", System.Data.SqlDbType.NText, surveyResponse.AdditionalComments, sqlCommand);
                AddParameterToCommand("@publishingApproval", System.Data.SqlDbType.Bit, surveyResponse.PublishingApproval, sqlCommand);
                AddParameterToCommand("@dateCreated", System.Data.SqlDbType.DateTime, DateTime.Now, sqlCommand);
                AddParameterToCommand("@surveyMonkeyResponseID", System.Data.SqlDbType.BigInt, surveyResponse.SurveyResponseID, sqlCommand);

                sqlConnection.Open();
                sqlCommand.ExecuteNonQuery();
            }

        }

        private static void FillSurveyResponse(long? questionId, string answer, SurveyResponse surveyResponse)
        {
            int likelyToRecommend = 0;

            if (questionId == Q_HowLikelyToRecommend)
            {
                if (!string.IsNullOrWhiteSpace(answer))
                {
                    int.TryParse(answer, out likelyToRecommend);
                    surveyResponse.HowLikelyToRecommend = likelyToRecommend;
                }
            }
            else if (questionId == Q_RecommendComments)
            {
                surveyResponse.RecommendComments = answer;
            }
            else if (questionId == Q_PhoneAgentRating)
            {
                surveyResponse.PhoneAgentRating = answer;
            }
            else if (questionId == Q_RVTechRating)
            {
                surveyResponse.RVTechRating = answer;
            }
            else if (questionId == Q_ServiceProviderRating)
            {
                surveyResponse.ServiceProviderRating = answer;
            }
            else if (questionId == Q_AdditionalComments)
            {
                surveyResponse.AdditionalComments = answer;
            }
            else if (questionId == Q_PublishingApproval)
                surveyResponse.PublishingApproval = false; /* If this question is answered, the answer is actually "No" :) */
        }

    }
}


