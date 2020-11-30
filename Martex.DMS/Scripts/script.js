window.name = "AmazonConnectWindow";
window.ClickToDial = false;
window.myCPP = window.myCPP || {};

// TODO: Amazon Connect URL change
//replace with the CCP URL for the current Amazon Connect instance
var ccpUrl = "https://coachnettest.awsapps.com/connect/ccp#/";

connect.core.initCCP(containerDiv, {
    ccpUrl: ccpUrl,
    loginPopup: true,
    softphone: {
        allowFramedSoftphone: true
    }
});
connect.contact(subscribeToContactEvents);
connect.agent(subscribeToAgentEvents);

function subscribeToContactEvents(contact) {
    window.myCPP.contact = contact;
    logInfoMsg("New contact offered. Subscribing to events for contact");
    if (contact.getActiveInitialConnection()
        && contact.getActiveInitialConnection().getEndpoint()) {
        logInfoMsg("New contact is from " + contact.getActiveInitialConnection().getEndpoint().phoneNumber);
    } else {
        logInfoMsg("This is an existing contact for this agent");
    }
    logInfoMsg("Contact is from queue " + contact.getQueue().name);
    logInfoMsg("ContactID is " + contact.getContactId());
    logInfoMsg("Contact attributes are " + JSON.stringify(contact.getAttributes()));


    updateQueue(contact.getQueue().name);
    updateContactAttribute(contact.getAttributes());
    sendCallDataToODIS(contact);
    contact.onEnded(clearContactAttribute);
}

function updateQueue(msg) {
    var tableRef = document.getElementById('attributesTable');
    var cell1 = document.createElement('div');
    var cell2 = document.createElement('div');
    tableRef.appendChild(cell1);
    tableRef.appendChild(cell2);
    cell1.innerHTML = "<strong> Queue Name: </strong>";
    cell2.innerHTML = msg;

}


function updateContactAttribute(msg) {
    var tableRef = document.getElementById('attributesTable');
    for (var key in msg) {
        if (msg.hasOwnProperty(key)) {
            var cell1 = document.createElement('div');
            var cell2 = document.createElement('div');
            tableRef.appendChild(cell1);
            tableRef.appendChild(cell2);
            cell1.innerHTML = "<strong>" + key + "</strong>:";
            cell2.innerHTML = msg[key]['value'];
        }
    }

}


function clearContactAttribute() {
    var old_tbody = document.getElementById('attributesTable');
    old_tbody.innerHTML = "<!-- Contact attributes will go here-->";
}


function logMsgToScreen(msg) {
    logMsgs.innerHTML = new Date().toLocaleTimeString() + ' : ' + msg + '<br>' + logMsgs.innerHTML;
}


function logInfoMsg(msg) {
    connect.getLog().info(msg);
    logMsgToScreen(msg);
}


// LogMessages section display controls

var showLogsBtn = document.getElementById('showAttributes');
var showLogsDiv = document.getElementById('hiddenAttributes');
var hideLogsBtn = document.getElementById('hideAttributes');
var hideLogsDiv = document.getElementById('visibleAttributes');


showLogsBtn.addEventListener('click', replaceDisplay);

hideLogsBtn.addEventListener('click', replaceDisplay);

function replaceDisplay() {
    showLogsDiv.style.display = showLogsDiv.style.display === 'none' ? '' : 'none';
    hideLogsDiv.style.display = hideLogsDiv.style.display === 'none' ? '' : 'none';
}

function sendCallDataToODIS(contact) {
    const amazoncontactID = contact.getActiveInitialConnection()["contactId"];

    let connection = new connect.Connection(contact.getActiveInitialConnection()["contactId"], contact.getActiveInitialConnection()["connectionId"]);

    if (connection.getType() === "inbound") {
      let customerNumber = contact.getActiveInitialConnection().getEndpoint().phoneNumber;

        // This is used to spoof program numbers in test environments.
        // This should pull the proper number for production.
        let UserCalledTo = contact.getAttributes().UserCalledTo.value;

        let formattedCustomerNumber = customerNumber.replace("+", "");
        let formattedUserCalled = UserCalledTo.replace("+", "");

        let finalFormattedCustomerNumber = formattedCustomerNumber[0] + " " + customerNumber.slice(2);
        let finalFormattedUserCalled = formattedUserCalled[0] + " " + UserCalledTo.slice(2);

        window.open(`/Application/Request?isFromConnect=true&memberPhoneNumber=${finalFormattedCustomerNumber}&inBoundNumber=${finalFormattedUserCalled}`, "ODISWindow");

        $.ajax({
            type: 'POST',
            url: '/Request/SetAttributeSession',
            traditional: true,
            data: { "AmazonConnectID": amazoncontactID },
            cache: false,
            async: true,
            success: function (msg) {
                console.log(msg);
            },
        });

    } else if (connection.getType() === "outbound") {
        let phoneNumber; 

        if (window.ClickToDial) {
            phoneNumber = window.Number;
        } else {
            phoneNumber = contact.getActiveInitialConnection().getEndpoint().phoneNumber;
            phoneNumber = phoneNumber.replace("sip:+", "");
            phoneNumber = phoneNumber.replace("@lily-outbound", "");
            phoneNumber = phoneNumber[0] + " " + phoneNumber.slice(1);
        }

        $.ajax({
            type: 'POST',
            url: '/Request/UpdateServiceRequestOutboundCall',
            traditional: true,
            data: { "phoneNumber": phoneNumber, "amazonConnectID": amazoncontactID, "contactCategoryID": window.ContactCategoryID, "contactTypeID": window.ContactTypeID, "serviceRequestID": window.ServiceRequestID, "clickToDial": window.ClickToDial },
            cache: false,
            async: true,
            success: function (msg) {
                console.log(msg);
                window.ClickToDial = false;
                window.Number = "";
                window.ServiceRequestID = "";
                window.ContactCategoryID = "";
                window.ContactTypeID = "";
            },
        }); 
    }
}

function subscribeToAgentEvents(agent) {
    window.myCPP.agent = agent;
};

function callOutBound(number, serviceRequestId, ContactCategoryID, ContactTypeID) {
    const endPoint = connect.Endpoint.byPhoneNumber("+" + number);

    window.ClickToDial = true;
    window.Number = number;
    window.ServiceRequestID = serviceRequestId;
    window.ContactCategoryID = ContactCategoryID;
    window.ContactTypeID = ContactTypeID;

    window.myCPP.agent.connect(endPoint, {
        success: (s) => {
           console.log("Successful click to dial call")
        },
        failure: function () { console.log("failed") }
    });
};
