<!-- tour guide -->

// This whole file / intro business is one huge hack. I'd go look somewhere else if you're looking for a good time.

var intro;
// gaaaah. no nice way to hook into buttons on step 1 of tour.
// there's no callback which fires after the template's been rendered.
window.goToStep = function(i){
    intro.goToStep(i);
};
function mkIntro(){
    var startingLocation = location.hash;
    if (intro && !intro.hasQuit) intro.exit();
    var killItWithFire = function(){ intro.hasQuit = true; location.hash = startingLocation; }
    intro = introJs()
        .oncomplete(killItWithFire)
        .onexit(killItWithFire);
    var examples = {
        "square" : "#i=1&r=S%20%3A%20F%2BF%2BF%2BF&p.size=100,0&p.angle=90,0&s.size=0.8,1&s.angle=2,1&offsets=0,0,0",
        "square-recursive" : "#i=4&r=S%20%3A%20F%2BS&p.size=100,0&p.angle=90,0&s.size=0.6,1&s.angle=2.8,1&offsets=0,0,0",
        "spirograph" : "#i=50&r=A%20%3A%20%5BS%5D%2BA%0AS%20%3A%20F%2BS&p.size=100,0&p.angle=90,0&s.size=0.6,1&s.angle=2.8,1&offsets=0,0,0",
        "serpinski" : "#i=8&r=A%20%3A%20BF-AF-B%0AB%20%3A%20AF%2BBF%2BA&p.size=1.0352999999999999,0.010817999999999967&p.angle=60,0&s.size=200,1000000&s.angle=200,1000000&offsets=-124,87,30"
    };
    var steps = $('#tour li').map(function(){
        var step = $(this);
        return {
            "element" : step.data('element'),
            "intro" : step.html(),
            "position" : step.data('position') || "right",
            "data" : step.data()
        }
    });

    return intro.onbeforechange(function(){
        if (intro._currentStep == undefined){
            intro.goToStep(1);
            $('.introjs-tooltipbuttons').hide();
        }else{
            $('.introjs-tooltipbuttons').show();
        }
    }).onchange(function(){
            var item = intro._introItems[intro._currentStep];
            var data = item.data;
            if (data.example) window.location.hash = examples[data.example];
            if (data.overlay == 'on') $('.introjs-overlay').show();
            if (data.overlay == 'off') $('.introjs-overlay').hide();
        }).setOptions({
            exitOnOverlayClick: true,
            tooltipPosition:'right',
            showStepNumbers: false,
            steps: steps
        });
}


$('#helpTrigger').click(function(){
    mkIntro().start();
    return false;
});

$('#syntaxTrigger').click(function(){
    mkIntro().start().goToStep(13);
    return false;
});