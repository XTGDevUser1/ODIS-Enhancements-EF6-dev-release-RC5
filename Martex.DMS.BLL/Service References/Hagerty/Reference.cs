﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.BLL.Hagerty {
    using System.Runtime.Serialization;
    using System;
    
    
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Runtime.Serialization", "4.0.0.0")]
    [System.Runtime.Serialization.DataContractAttribute(Name="ResponseData", Namespace="http://schemas.datacontract.org/2004/07/Hagerty.NMC.Service.Data")]
    [System.SerializableAttribute()]
    public partial class ResponseData : object, System.Runtime.Serialization.IExtensibleDataObject, System.ComponentModel.INotifyPropertyChanged {
        
        [System.NonSerializedAttribute()]
        private System.Runtime.Serialization.ExtensionDataObject extensionDataField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string CustomerNumberField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private System.Collections.Generic.List<Martex.DMS.BLL.Hagerty.PolicyVehicles> PolicyVehicleResponseField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string ResponseMessageField;
        
        [global::System.ComponentModel.BrowsableAttribute(false)]
        public System.Runtime.Serialization.ExtensionDataObject ExtensionData {
            get {
                return this.extensionDataField;
            }
            set {
                this.extensionDataField = value;
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string CustomerNumber {
            get {
                return this.CustomerNumberField;
            }
            set {
                if ((object.ReferenceEquals(this.CustomerNumberField, value) != true)) {
                    this.CustomerNumberField = value;
                    this.RaisePropertyChanged("CustomerNumber");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public System.Collections.Generic.List<Martex.DMS.BLL.Hagerty.PolicyVehicles> PolicyVehicleResponse {
            get {
                return this.PolicyVehicleResponseField;
            }
            set {
                if ((object.ReferenceEquals(this.PolicyVehicleResponseField, value) != true)) {
                    this.PolicyVehicleResponseField = value;
                    this.RaisePropertyChanged("PolicyVehicleResponse");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string ResponseMessage {
            get {
                return this.ResponseMessageField;
            }
            set {
                if ((object.ReferenceEquals(this.ResponseMessageField, value) != true)) {
                    this.ResponseMessageField = value;
                    this.RaisePropertyChanged("ResponseMessage");
                }
            }
        }
        
        public event System.ComponentModel.PropertyChangedEventHandler PropertyChanged;
        
        protected void RaisePropertyChanged(string propertyName) {
            System.ComponentModel.PropertyChangedEventHandler propertyChanged = this.PropertyChanged;
            if ((propertyChanged != null)) {
                propertyChanged(this, new System.ComponentModel.PropertyChangedEventArgs(propertyName));
            }
        }
    }
    
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Runtime.Serialization", "4.0.0.0")]
    [System.Runtime.Serialization.DataContractAttribute(Name="PolicyVehicles", Namespace="http://schemas.datacontract.org/2004/07/Hagerty.NMC.Service.Data")]
    [System.SerializableAttribute()]
    public partial class PolicyVehicles : object, System.Runtime.Serialization.IExtensibleDataObject, System.ComponentModel.INotifyPropertyChanged {
        
        [System.NonSerializedAttribute()]
        private System.Runtime.Serialization.ExtensionDataObject extensionDataField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string BodyStyleField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string MakeField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string ModelField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string PolicyIDField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string VehicleTypeField;
        
        [System.Runtime.Serialization.OptionalFieldAttribute()]
        private string YearField;
        
        [global::System.ComponentModel.BrowsableAttribute(false)]
        public System.Runtime.Serialization.ExtensionDataObject ExtensionData {
            get {
                return this.extensionDataField;
            }
            set {
                this.extensionDataField = value;
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string BodyStyle {
            get {
                return this.BodyStyleField;
            }
            set {
                if ((object.ReferenceEquals(this.BodyStyleField, value) != true)) {
                    this.BodyStyleField = value;
                    this.RaisePropertyChanged("BodyStyle");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string Make {
            get {
                return this.MakeField;
            }
            set {
                if ((object.ReferenceEquals(this.MakeField, value) != true)) {
                    this.MakeField = value;
                    this.RaisePropertyChanged("Make");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string Model {
            get {
                return this.ModelField;
            }
            set {
                if ((object.ReferenceEquals(this.ModelField, value) != true)) {
                    this.ModelField = value;
                    this.RaisePropertyChanged("Model");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string PolicyID {
            get {
                return this.PolicyIDField;
            }
            set {
                if ((object.ReferenceEquals(this.PolicyIDField, value) != true)) {
                    this.PolicyIDField = value;
                    this.RaisePropertyChanged("PolicyID");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string VehicleType {
            get {
                return this.VehicleTypeField;
            }
            set {
                if ((object.ReferenceEquals(this.VehicleTypeField, value) != true)) {
                    this.VehicleTypeField = value;
                    this.RaisePropertyChanged("VehicleType");
                }
            }
        }
        
        [System.Runtime.Serialization.DataMemberAttribute()]
        public string Year {
            get {
                return this.YearField;
            }
            set {
                if ((object.ReferenceEquals(this.YearField, value) != true)) {
                    this.YearField = value;
                    this.RaisePropertyChanged("Year");
                }
            }
        }
        
        public event System.ComponentModel.PropertyChangedEventHandler PropertyChanged;
        
        protected void RaisePropertyChanged(string propertyName) {
            System.ComponentModel.PropertyChangedEventHandler propertyChanged = this.PropertyChanged;
            if ((propertyChanged != null)) {
                propertyChanged(this, new System.ComponentModel.PropertyChangedEventArgs(propertyName));
            }
        }
    }
    
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    [System.ServiceModel.ServiceContractAttribute(ConfigurationName="Hagerty.INMCService")]
    public interface INMCService {
        
        [System.ServiceModel.OperationContractAttribute(Action="http://tempuri.org/ICommonService/ServiceIsRunning", ReplyAction="http://tempuri.org/ICommonService/ServiceIsRunningResponse")]
        bool ServiceIsRunning();
        
        [System.ServiceModel.OperationContractAttribute(Action="http://tempuri.org/ICommonService/ServiceInfo", ReplyAction="http://tempuri.org/ICommonService/ServiceInfoResponse")]
        System.Collections.Generic.List<string> ServiceInfo();
        
        [System.ServiceModel.OperationContractAttribute(Action="http://tempuri.org/INMCService/GetResponseData", ReplyAction="http://tempuri.org/INMCService/GetResponseDataResponse")]
        Martex.DMS.BLL.Hagerty.ResponseData GetResponseData(int CustomerNumber);
    }
    
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    public interface INMCServiceChannel : Martex.DMS.BLL.Hagerty.INMCService, System.ServiceModel.IClientChannel {
    }
    
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    public partial class NMCServiceClient : System.ServiceModel.ClientBase<Martex.DMS.BLL.Hagerty.INMCService>, Martex.DMS.BLL.Hagerty.INMCService {
        
        public NMCServiceClient() {
        }
        
        public NMCServiceClient(string endpointConfigurationName) : 
                base(endpointConfigurationName) {
        }
        
        public NMCServiceClient(string endpointConfigurationName, string remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public NMCServiceClient(string endpointConfigurationName, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public NMCServiceClient(System.ServiceModel.Channels.Binding binding, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(binding, remoteAddress) {
        }
        
        public bool ServiceIsRunning() {
            return base.Channel.ServiceIsRunning();
        }
        
        public System.Collections.Generic.List<string> ServiceInfo() {
            return base.Channel.ServiceInfo();
        }
        
        public Martex.DMS.BLL.Hagerty.ResponseData GetResponseData(int CustomerNumber) {
            return base.Channel.GetResponseData(CustomerNumber);
        }
    }
}
