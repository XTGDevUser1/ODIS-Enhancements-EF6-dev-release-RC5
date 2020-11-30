﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Martex.DMS.DAL.DMSBaseException;

namespace  ClientPortal.Models
{
    public sealed class OperationStatus
    {
        public const string SUCCESS = "Success";
        public const string ERROR = "Error";
        public const string BUSINESS_RULE_FAIL = "BusinessRuleFail";
    }

    public class OperationResult
    {
        public string OperationType { get; set; }
        public string Status { get; set; }

        public string TabNavigation { get; set; }
        // The following two properties hold good in the case of an error
        public string ErrorMessage { get; set; }
        public string ErrorDetail { get; set; }
        // Custom data to be returned in the case of success
        public object Data { get; set; }

        public OperationResult()
        {

        }
    }
}