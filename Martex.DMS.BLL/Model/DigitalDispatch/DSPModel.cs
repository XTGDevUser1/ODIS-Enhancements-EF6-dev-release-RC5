using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class DSPModel : DigitalDispatchHeaderModel
    {

        //#region DSPMessageBody

        //#region AccountInfo
        public string MemFirstName { get; set; }
        public string MemLastName { get; set; }
        public string CustFirstName { get; set; }
        public string CustLastName { get; set; }

        //#region MailAddr
        public string Addr1 { get; set; }
        public string Addr2 { get; set; }
        public string City { get; set; }
        public string State { get; set; }
        public string Zip { get; set; }
        public string Phone { get; set; }
        //#endregion

        public string CallBackPhone { get; set; }
        public string CallFromLoc { get; set; }
        public string DriversLic { get; set; }
        public string DLState { get; set; }
        public string MemNum { get; set; }
        public string AvailBenefits { get; set; }
        public string BenefitLimit { get; set; }
        //#endregion

        //#region JobInfo
        public string RequiredAcknowledgeTime { get; set; }
        public string JobID { get; set; }
        public DateTime? TimeStamp { get; set; }
        public int? MaxETA { get; set; }
        public string PrimaryTask { get; set; }
        #region Secondary Tasks
        public string Task { get; set; }
        #endregion
        public string Priority { get; set; }
        public string JobDesc { get; set; }
        public string HazMat { get; set; }

        //#endregion

        //#region Vehicle Info
        public int? Year { get; set; }
        public string Color { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public string Lic { get; set; }
        public string VehicleInfoState { get; set; }
        public string VIN { get; set; }
        public string VehicleType { get; set; }
        public string FuelType { get; set; }
        public string Odometer { get; set; }
        public string EngType { get; set; }
        public string TrailerWt { get; set; }
        public string TrailerCont { get; set; }
        public string AdditionalInfo { get; set; }
        //#endregion
        //#region IncAddr
        public string IncAddressTimeZone { get; set; }
        public string IncAddressAddr1 { get; set; }
        public string IncAddressAddr2 { get; set; }
        public string IncAddressCity { get; set; }
        public string IncAddressState { get; set; }
        public string IncAddressZip { get; set; }
        public string CrsStr1 { get; set; }
        public string CrsStr2 { get; set; }
        public string CallBox { get; set; }
        public string Landmark { get; set; }
        public string MileMarker { get; set; }
        public string LocCode { get; set; }
        public string DriverLoc { get; set; }
        public string DriverETA { get; set; }
        public string SafeLoc { get; set; }
        public string Median { get; set; }
        public string RtShoulder { get; set; }
        public string DirTravel { get; set; }
        public string PersonsInCar { get; set; }
        public string OnOffRamp { get; set; }
        public string ExitNum { get; set; }
        public string IncAddressLat { get; set; }
        public string IncAddressLon { get; set; }
        public string IncAddressGeoDatum { get; set; }
        //#endregion

        //#region DestAddr
        public string DestAddressLocInfo { get; set; }
        public string DestAddressAddr1 { get; set; }
        public string DestAddressAddr2 { get; set; }
        public string DestAddressCity { get; set; }
        public string DestAddressState { get; set; }
        public string DestAddressZip { get; set; }
        public string DestAddressPhone { get; set; }
        public string DestAddressLat { get; set; }
        public string DestAddressLon { get; set; }
        public string DestAddressGeoDatum { get; set; }
        //#endregion

        //#region Payment Info
        public string PONum { get; set; }
        public decimal? QuotePrice { get; set; }
        public decimal? AmntPaid { get; set; }
        public string PayType { get; set; }
        public string Auth { get; set; }
        public DateTime? ExpDate { get; set; }
        public string PayRef { get; set; }
        public string CashCall { get; set; }
        //#endregion
        //#endregion



    }
}
