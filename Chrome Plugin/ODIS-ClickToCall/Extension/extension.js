chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
   if (request.greeting == "hello"){
       chrome.runtime.sendNativeMessage("com.martex.deviceidreader",{ text: "Hello" },function(response) {
				chrome.tabs.query({active: true, currentWindow: true}, function(tabs){
					chrome.tabs.sendMessage(tabs[0].id, response, function(response) {});  
	}			);
			  });
		}
  });