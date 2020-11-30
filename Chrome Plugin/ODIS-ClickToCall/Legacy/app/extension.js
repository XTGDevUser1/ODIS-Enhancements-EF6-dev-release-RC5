chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
		document.getElementById('odisfield').value = request.message.text;
	}
);
