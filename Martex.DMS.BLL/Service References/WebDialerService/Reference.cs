﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.42000
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.BLL.WebDialerService {
    
    
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    [System.ServiceModel.ServiceContractAttribute(Namespace="urn:WD70", ConfigurationName="WebDialerService.WDSoapInterface")]
    public interface WDSoapInterface {
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="makeCallSoapReturn")]
        Martex.DMS.BLL.WebDialerService.CallResponse makeCallSoap(Martex.DMS.BLL.WebDialerService.Credential in0, string in1, Martex.DMS.BLL.WebDialerService.UserProfile in2);
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="endCallSoapReturn")]
        Martex.DMS.BLL.WebDialerService.CallResponse endCallSoap(Martex.DMS.BLL.WebDialerService.Credential in0, Martex.DMS.BLL.WebDialerService.UserProfile in1);
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="getProfileSoapReturn")]
        Martex.DMS.BLL.WebDialerService.GetConfigResponse getProfileSoap(Martex.DMS.BLL.WebDialerService.Credential in0, string in1);
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="isClusterUserSoapReturn")]
        bool isClusterUserSoap(string in0);
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="getProfileDetailSoapReturn")]
        Martex.DMS.BLL.WebDialerService.ConfigResponseDetail getProfileDetailSoap(Martex.DMS.BLL.WebDialerService.Credential in0);
        
        [System.ServiceModel.OperationContractAttribute(Action="", ReplyAction="*")]
        [System.ServiceModel.XmlSerializerFormatAttribute(Style=System.ServiceModel.OperationFormatStyle.Rpc, SupportFaults=true, Use=System.ServiceModel.OperationFormatUse.Encoded)]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfoDetail))]
        [System.ServiceModel.ServiceKnownTypeAttribute(typeof(WDDeviceInfo))]
        [return: System.ServiceModel.MessageParameterAttribute(Name="getPrimaryLineReturn")]
        string getPrimaryLine(Martex.DMS.BLL.WebDialerService.Credential in0);
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class Credential : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string userIDField;
        
        private string passwordField;
        
        /// <remarks/>
        public string userID {
            get {
                return this.userIDField;
            }
            set {
                this.userIDField = value;
                this.RaisePropertyChanged("userID");
            }
        }
        
        /// <remarks/>
        public string password {
            get {
                return this.passwordField;
            }
            set {
                this.passwordField = value;
                this.RaisePropertyChanged("password");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class WDDeviceInfoDetail : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string deviceNameField;
        
        private string[] linesField;
        
        private string phoneDescField;
        
        private string phoneTypeField;
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public string deviceName {
            get {
                return this.deviceNameField;
            }
            set {
                this.deviceNameField = value;
                this.RaisePropertyChanged("deviceName");
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public string[] lines {
            get {
                return this.linesField;
            }
            set {
                this.linesField = value;
                this.RaisePropertyChanged("lines");
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public string phoneDesc {
            get {
                return this.phoneDescField;
            }
            set {
                this.phoneDescField = value;
                this.RaisePropertyChanged("phoneDesc");
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public string phoneType {
            get {
                return this.phoneTypeField;
            }
            set {
                this.phoneTypeField = value;
                this.RaisePropertyChanged("phoneType");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class ConfigResponseDetail : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string descriptionField;
        
        private WDDeviceInfoDetail[] deviceInfoListDetailField;
        
        private int responseCodeField;
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public string description {
            get {
                return this.descriptionField;
            }
            set {
                this.descriptionField = value;
                this.RaisePropertyChanged("description");
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.SoapElementAttribute(IsNullable=true)]
        public WDDeviceInfoDetail[] deviceInfoListDetail {
            get {
                return this.deviceInfoListDetailField;
            }
            set {
                this.deviceInfoListDetailField = value;
                this.RaisePropertyChanged("deviceInfoListDetail");
            }
        }
        
        /// <remarks/>
        public int responseCode {
            get {
                return this.responseCodeField;
            }
            set {
                this.responseCodeField = value;
                this.RaisePropertyChanged("responseCode");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class WDDeviceInfo : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string deviceNameField;
        
        private string[] linesField;
        
        /// <remarks/>
        public string deviceName {
            get {
                return this.deviceNameField;
            }
            set {
                this.deviceNameField = value;
                this.RaisePropertyChanged("deviceName");
            }
        }
        
        /// <remarks/>
        public string[] lines {
            get {
                return this.linesField;
            }
            set {
                this.linesField = value;
                this.RaisePropertyChanged("lines");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class GetConfigResponse : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string descriptionField;
        
        private WDDeviceInfo[] deviceInfoListField;
        
        private int responseCodeField;
        
        /// <remarks/>
        public string description {
            get {
                return this.descriptionField;
            }
            set {
                this.descriptionField = value;
                this.RaisePropertyChanged("description");
            }
        }
        
        /// <remarks/>
        public WDDeviceInfo[] deviceInfoList {
            get {
                return this.deviceInfoListField;
            }
            set {
                this.deviceInfoListField = value;
                this.RaisePropertyChanged("deviceInfoList");
            }
        }
        
        /// <remarks/>
        public int responseCode {
            get {
                return this.responseCodeField;
            }
            set {
                this.responseCodeField = value;
                this.RaisePropertyChanged("responseCode");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class CallResponse : object, System.ComponentModel.INotifyPropertyChanged {
        
        private int responseCodeField;
        
        private string responseDescriptionField;
        
        /// <remarks/>
        public int responseCode {
            get {
                return this.responseCodeField;
            }
            set {
                this.responseCodeField = value;
                this.RaisePropertyChanged("responseCode");
            }
        }
        
        /// <remarks/>
        public string responseDescription {
            get {
                return this.responseDescriptionField;
            }
            set {
                this.responseDescriptionField = value;
                this.RaisePropertyChanged("responseDescription");
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
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.Xml", "4.6.1064.2")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.SoapTypeAttribute(Namespace="urn:WD70")]
    public partial class UserProfile : object, System.ComponentModel.INotifyPropertyChanged {
        
        private string userField;
        
        private string deviceNameField;
        
        private string lineNumberField;
        
        private bool supportEMField;
        
        private string localeField;
        
        private bool dontAutoCloseField;
        
        private bool dontShowCallConfField;
        
        /// <remarks/>
        public string user {
            get {
                return this.userField;
            }
            set {
                this.userField = value;
                this.RaisePropertyChanged("user");
            }
        }
        
        /// <remarks/>
        public string deviceName {
            get {
                return this.deviceNameField;
            }
            set {
                this.deviceNameField = value;
                this.RaisePropertyChanged("deviceName");
            }
        }
        
        /// <remarks/>
        public string lineNumber {
            get {
                return this.lineNumberField;
            }
            set {
                this.lineNumberField = value;
                this.RaisePropertyChanged("lineNumber");
            }
        }
        
        /// <remarks/>
        public bool supportEM {
            get {
                return this.supportEMField;
            }
            set {
                this.supportEMField = value;
                this.RaisePropertyChanged("supportEM");
            }
        }
        
        /// <remarks/>
        public string locale {
            get {
                return this.localeField;
            }
            set {
                this.localeField = value;
                this.RaisePropertyChanged("locale");
            }
        }
        
        /// <remarks/>
        public bool dontAutoClose {
            get {
                return this.dontAutoCloseField;
            }
            set {
                this.dontAutoCloseField = value;
                this.RaisePropertyChanged("dontAutoClose");
            }
        }
        
        /// <remarks/>
        public bool dontShowCallConf {
            get {
                return this.dontShowCallConfField;
            }
            set {
                this.dontShowCallConfField = value;
                this.RaisePropertyChanged("dontShowCallConf");
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
    public interface WDSoapInterfaceChannel : Martex.DMS.BLL.WebDialerService.WDSoapInterface, System.ServiceModel.IClientChannel {
    }
    
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.CodeDom.Compiler.GeneratedCodeAttribute("System.ServiceModel", "4.0.0.0")]
    public partial class WDSoapInterfaceClient : System.ServiceModel.ClientBase<Martex.DMS.BLL.WebDialerService.WDSoapInterface>, Martex.DMS.BLL.WebDialerService.WDSoapInterface {
        
        public WDSoapInterfaceClient() {
        }
        
        public WDSoapInterfaceClient(string endpointConfigurationName) : 
                base(endpointConfigurationName) {
        }
        
        public WDSoapInterfaceClient(string endpointConfigurationName, string remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public WDSoapInterfaceClient(string endpointConfigurationName, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(endpointConfigurationName, remoteAddress) {
        }
        
        public WDSoapInterfaceClient(System.ServiceModel.Channels.Binding binding, System.ServiceModel.EndpointAddress remoteAddress) : 
                base(binding, remoteAddress) {
        }
        
        public Martex.DMS.BLL.WebDialerService.CallResponse makeCallSoap(Martex.DMS.BLL.WebDialerService.Credential in0, string in1, Martex.DMS.BLL.WebDialerService.UserProfile in2) {
            return base.Channel.makeCallSoap(in0, in1, in2);
        }
        
        public Martex.DMS.BLL.WebDialerService.CallResponse endCallSoap(Martex.DMS.BLL.WebDialerService.Credential in0, Martex.DMS.BLL.WebDialerService.UserProfile in1) {
            return base.Channel.endCallSoap(in0, in1);
        }
        
        public Martex.DMS.BLL.WebDialerService.GetConfigResponse getProfileSoap(Martex.DMS.BLL.WebDialerService.Credential in0, string in1) {
            return base.Channel.getProfileSoap(in0, in1);
        }
        
        public bool isClusterUserSoap(string in0) {
            return base.Channel.isClusterUserSoap(in0);
        }
        
        public Martex.DMS.BLL.WebDialerService.ConfigResponseDetail getProfileDetailSoap(Martex.DMS.BLL.WebDialerService.Credential in0) {
            return base.Channel.getProfileDetailSoap(in0);
        }
        
        public string getPrimaryLine(Martex.DMS.BLL.WebDialerService.Credential in0) {
            return base.Channel.getPrimaryLine(in0);
        }
    }
}
