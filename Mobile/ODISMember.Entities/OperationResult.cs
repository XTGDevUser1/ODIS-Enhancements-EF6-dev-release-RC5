using System;

namespace ODISMember.Entities
{
	public class OperationResult
	{
		public string OperationType { get; set; }
		public string Status { get; set; }
		public string TabNavigation { get; set; }
		public string ErrorMessage { get; set; }
		public string ErrorDetail { get; set; }
		public object Data { get; set; }

	}
}
