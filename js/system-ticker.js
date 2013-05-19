(function ($) {
    $.fn.ticker = function (location) {
        return this.each(function () {
            var el = $(this);

            $.getJSON(location, "", function (data) {
                el.html("");
                $(data.systems).each(function (i, sys) {
                    el.append(
                        $("<li></li>")
                            .addClass("elem")
                            .append(
                            $('<a href="' + sys.url + '"></a>')
                                .click(function(){
                                    $("#systemName").html(sys.name);
                                    $("#systemInfo").addClass("blue").slideDown();
                                })
                                .append(
                                    $('<div class="elem-author"></div>').append(sys.author)
                                )
                                .append( $('<div class="img-holder"></div>')
                                    .append('<img src="img/'+ (sys.img ? "systems/"+sys.img : "100x100.gif")+'" alt="">')
                                    .append('<div class="elem-label ellipsis">' + sys.name + '</div>')
                            ))
                    );
                });
                $(".ellipsis").ellipsis();
            });

        });
    };
})(jQuery);
