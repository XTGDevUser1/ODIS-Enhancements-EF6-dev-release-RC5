﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.BLL.TowBookServiceReference {
    
    
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    [System.ServiceModel.ServiceContractAttribute(ConfigurationName="TowBookServiceReference.ITowbookRequestHandler")]
    public interface ITowbookRequestHandler {
        
        [System.ServiceModel.OperationContractAttribute(Action="http://tempuri.org/ITowbookRequestHandler/Process", ReplyAction="http://tempuri.org/ITowbookRequestHandler/ProcessResponse")]
        string Process(string message, string key);
    }
    
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    public interface ITowbookRequestHandlerChannel : Martex.DMS.BLL.TowBookServiceReference.ITowbookRequestHandler, System.ServiceModel.IClientChannel {
    }
    
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    public partial class TowbookRequestHandlerClient : System.ServiceModel.ClientBase<Martex.DMS.BLL.TowBookServiceReference.ITowbookRequestHandler>, Martex.DMS.BLL.TowBookServiceReference.ITowbookRequestHandler {
        
        public TowbookRequestHandlerClient() {
        }
        
        public TowbookRequestHandlerClient(string endpointConfigurationName) : 
                base(endpointConfigurationName) {
        }
        
        public TowbookRequestHandlerClient(string endpointConfigurationName, string remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public TowbookRequestHandlerClient(string endpointConfigurationName, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public TowbookRequestHandlerClient(System.ServiceModel.Channels.Binding binding, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(binding, remoteAddress) {
        }
        
        public string Process(string message, string key) {
            return base.Channel.Process(message, key);
        }
    }
}
