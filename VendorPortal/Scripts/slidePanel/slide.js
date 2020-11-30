$(document).ready(function () {

    // Expand Panel
    $("#Hslideopen").click(function () {
        $("div.hpanel").slideDown("slow");
    });

    // Collapse Panel
    $("#Hslideclose").click(function () {        
        $("div.hpanel").slideUp("slow");        
    });

    // Switch buttons from "Log In | Register" to "Close Panel" on click
    $("#toggle a").click(function () {
        $("#toggle a").toggle();
    });

    // Expand Panel
    $("#Fslideopen").click(function () {
        $("div.fpanel").slideDown("slow");

    });

    // Collapse Panel
    $("#Fslideclose").click(function () {
        $("div.fpanel").slideUp("slow");
    });

    // Switch buttons from "Log In | Register" to "Close Panel" on click
    $("#toggleFooter a").click(function () {
        $("#toggleFooter a").toggle();
    });

});