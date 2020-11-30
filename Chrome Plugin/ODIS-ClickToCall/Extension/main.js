chrome.runtime.sendMessage({greeting: "hello"}, function(response) {
  
});

chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
	  console.log(request);
	  var odisField = document.getElementById('odisfield');
	  if(odisField != null)
	  {
		odisField.value = request.text;
	  }
  });


