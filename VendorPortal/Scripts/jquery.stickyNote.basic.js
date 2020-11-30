(function ($) {

    var methods = {
        init: function (options) {

            //Set the default values, use comma to separate the settings, example:
            var defaults = {
                trigger: "",
                showOnLoad: true,
                content: "",
                autoSaveUrl: '',
                paramName: 'stickyText',
                left: "0px",
                top: "0px"
                // Let's worry about callbacks and auto save urls little later.
            }

            var options = $.extend(defaults, options);

            return this.each(function () {

                var $this = $(this),
                    data = $this.data('stickyNote')

                // If the plugin hasn't been initialized yet
                if (!data) {

                    /* Initialize */
                    var o = options;

                    var currentElement = $(this);

                    $(this).data('stickyNote', {
                        autoSave: true,
                        timerId: 0,
                        settings: options
                    });

                    // Render the layout for sticky note
                    var titleElement = $('<div class="stickyTitle">Clipboard<span class="info-spot on-left"><span class="icon-info-round"></span><span class="info-bubble">This window is for temporary note taking. Whatever you type here will be here until you delete it; however, it is not saved to the Service Request. Take notes in this window and then cut and paste the information onto the Service Reqeust. You should manually delete these notes before starting a new phone call.</span></span></div>').append('&nbsp;&nbsp;&nbsp;<span class="left closeicon">X</span>');
                    var txtElement = $('<textarea id="txtNote" class="stickyNote-editable"></textarea>');

                    //Set the height and width of text area
                    txtElement.css("width", (currentElement.width() - 5) + 'px');
                    txtElement.css("height", (currentElement.height() - 5) + 'px');

                    txtElement.val(unescape(options.content));
                    currentElement.append(titleElement);
                    currentElement.append($('<div/>').append(txtElement));

                    currentElement.resizable({
                        resize: function (event, ui) {
                            $(ui.element).css("position", "fixed");
                            var txtArea = $(ui.element).find(".stickyNote-editable");
                            txtArea.css("width", ($(ui.element).width() - 5) + 'px');
                            txtArea.css("height", ($(ui.element).height() - 5) + 'px');
                        }
                    }).draggable({ handle: ".stickyTitle" });

                    $(".closeicon").click(function () {
                        $('#btnStickyNoteBasic').click();
                        //methods._hide(currentElement);
                    });

                    if ($.trim(options.trigger).length > 0) {
                        /*$(options.trigger).click(function () {
                        alert('test');
                        methods._show(currentElement);
                        });*/
                        $(options.trigger).toggle(function () {
                            methods._show(currentElement);
                        },
                        function () {
                            methods._hide(currentElement);
                        });

                    }
                    // Hide element if need be.
                    if (!options.showOnLoad) {
                        methods._hide(currentElement);
                    }
                    else {
                        methods._show(currentElement);
                    }

                    if (options.left != "0px") {
                        currentElement.css("left", options.left);
                    }
                    else {
                        currentElement.css("right", "200px");
                    }
                    if (options.top != "0px") {
                        currentElement.css("top", options.top);
                    }
                    else {
                        currentElement.css("top", "50px");
                    }
                }
            });

        },

        _show: function (currentElement) {
            currentElement.css("visibility", "visible");
            currentElement.show('blind');
            currentElement.data('stickyNote').autoSave = true;
            methods._save(currentElement);

        },
        _hide: function (currentElement) {
            currentElement.hide('blind');
            clearInterval(currentElement.data('stickyNote').timerId);
            currentElement.data('stickyNote').timerId = 0;
            currentElement.data('stickyNote').autoSave = false;

            var $stickyNoteData = currentElement.data('stickyNote');

            if ($stickyNoteData.settings.autoSaveUrl) {

                $.ajax($stickyNoteData.settings.autoSaveUrl, {
                    type: 'POST',
                    global: false,
                    data: { stickyText: escape(currentElement.find(".stickyNote-editable").val()),
                        left: currentElement.css("left"),
                        top: currentElement.css("top"),
                        isOpen: false
                    },
                    success: function (json) { }
                });

            }

        },

        show: function () {
            methods._show($(this));
        },
        hide: function () {
            methods._hide($(this));
        },
        _save: function (currentElement) {

            // TODO: Get rid of the following line
            //$("#lblAutoSaveStatus").html("Autosaved @ " + (new Date()).getTime());
            // Fire AJAX request to save the data
            var $stickyNoteData = currentElement.data('stickyNote');

            if ($stickyNoteData.settings.autoSaveUrl) {

                $.ajax($stickyNoteData.settings.autoSaveUrl, {
                    type: 'POST',
                    global: false,
                    data: { stickyText: escape(currentElement.find(".stickyNote-editable").val()),
                        left: currentElement.css("left"),
                        top: currentElement.css("top"),
                        isOpen: currentElement.css("display") == "block"
                    },
                    success: function (json) { }
                });

            }

            if ($stickyNoteData.autoSave) {

                if ($stickyNoteData.timerId == 0) {
                    var id = setInterval(function () { methods._save(currentElement); }, 3000);
                    $stickyNoteData.timerId = id;
                }
            }

        }
    };



    $.fn.extend({

        //pass the options variable to the function
        stickyNote: function (method) {

            // Method calling logic
            if (methods[method]) {
                return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
            } else if (typeof method === 'object' || !method) {
                return methods.init.apply(this, arguments);
            } else {
                $.error('Method ' + method + ' does not exist on jQuery.stickyNote');
            }

        }

    });

})(jQuery);