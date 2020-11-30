$(function () {
    $('#input_apiKey').attr("placeholder", "UserName:Password:OrganizationId");
});
$('#input_apiKey').change(function () {
    var key = $('#input_apiKey')[0].value;
    var credentials = key.split(':'); //username:password:organizationid expected
    $.ajax({
        url: "/Members/Login",
        type: "post",
        contenttype: 'x-www-form-urlencoded',
        beforeSend: function (request) {
            request.setRequestHeader("OrganizationId", credentials[2]);
        },
        data: "grant_type=password&username=" + credentials[0] + "&password=" + credentials[1],
        success: function (response) {
            if (response.access_token == undefined) {
                alert("Login failed!");
            }
            else {
                alert("Login success!");
                var bearerToken = 'Bearer ' + response.access_token;
                swaggerUi.api.clientAuthorizations.add("key", new SwaggerClient.ApiKeyAuthorization("Authorization", bearerToken, "header"));
            }
        },
        error: function (xhr, ajaxoptions, thrownerror) {
            alert("Login failed!");
        }
    });
});

swaggerUi.api.clientAuthorizations.add("key", new SwaggerClient.ApiKeyAuthorization("X-APIKEY", '3c649fbbed000642181b173b8c43b814', "header"));