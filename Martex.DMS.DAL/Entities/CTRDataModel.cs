using System;

namespace Martex.DMS.DAL.Entities {
  public class CTRDataModel {
    public string ConnectContactID { get; set; }

    public string InitialContactID { get; set; }

    public string NextContactId { get; set; }

    public string PreviousContactID { get; set; }

    public string CustomerEndpoint { get; set; }

    public string CustomerEndpointType { get; set; }

    public string InitiationMethod { get; set; }

    public DateTime? InitiationTimestamp { get; set; }

    public string SystemEndpoint { get; set; }

    public string QueueARN { get; set; }

    public string QueueName { get; set; }

    public int? QueueDuration { get; set; }

    public DateTime? EnqueueTimestamp { get; set; }

    public DateTime? DequeueTimestamp { get; set; }

    public string AgentARN { get; set; }

    public string AgentUsername { get; set; }

    public string AgentRoutingProfileARN { get; set; }

    public string AgentRoutingProfileName { get; set; }

    public int? AgentNumberOfHolds { get; set; }

    public DateTime? ConnectedToAgentTimestamp { get; set; }

    public int? CustomerHoldDuration { get; set; }

    public int? LongestCustomerHoldDuration { get; set; }

    public DateTime? TransferCompletedTimestamp { get; set; }

    public string TransferredToEndpoint { get; set; }

    public int? AfterContactWorkDuration { get; set; }

    public DateTime? AfterContactWorkStartTimestamp { get; set; }

    public DateTime? AfterContactWorkEndTimestamp { get; set; }

    public int? AgentIntractionDuration { get; set; }

    public string Channel { get; set; }

    public DateTime? ConnectedToSystemTimestamp { get; set; }

    public DateTime? DisconnectTimestamp { get; set; }

    public string RecordingLocation { get; set; }

    public string RecordingStatus { get; set; }

    public string RecordingType { get; set; }

    public string RecordingDeletionReason { get; set; }

    public string AWSAccount { get; set; }

    public string InstanceARN { get; set; }

    public string CTRRecord { get; set; }
  }
}