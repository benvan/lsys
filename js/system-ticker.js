(function ($) {
    $.fn.ticker = function () {
        return this.each(function () {
            var el = $(this);

            $.getJSON("ticker.json", "", function (data) {
                el.html("");
                $(data.systems).each(function (i, sys) {
                    el.append(
                        $("<li></li>")
                            .addClass("elem")
                            .append(
                            $('<a href="' + sys.url + '"></a>')
                                .click(function(){
                                    $("#systemName").html(sys.name);
                                    $("#systemInfo").addClass("blue");
                                })
                                .append( $('<div></div>')
                                    .append('<img src="img/100x100.gif" alt="">')
                                    .append('<div class="elem-label ellipsis">' + sys.name + '</div>')
                            ))
                    );
                });
                $(".ellipsis").ellipsis();
            });


        });
    };
})(jQuery);