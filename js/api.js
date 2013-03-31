api = {
    user: {
        token:{},
        setToken:function(token){
            api.user.token = token;
            api.user.name = token.substring(token.indexOf("%")+1,token.length);
            $.cookie("token", token);
        },
        logout: function(){
            api.token = {};
            $.removeCookie("token");
        },
        login: function (username, password, success, failure) {
            $.ajax({
                type:"POST",
                url:"http://localhost:9000/login",
                data:{
                    username: username,
                    password: password
                },
                success:function (data) {
                    api.user.setToken(data.token);
                    success();
                },
                dataType:"json"
            }).fail(toJson(failure));
        },
        register: function (username, password, email, success, failure) {
            $.ajax({
                type:"POST",
                url:"http://localhost:9000/register",
                data:{
                    username: username,
                    password: password,
                    email: email
                },
                success:function (data) {
                    api.user.setToken(data.token);
                    success();
                },
                dataType:"json"
            }).fail(toJson(failure));
        }
    },
    system: {
        all: function () {
            $.getJSON("http://localhost:9000/system/all").done(LOG).fail(FAIL);
        },
        add: function (name, author, system) {
            $.ajax({
                url: "http://localhost:9000/system",
                type:"post",
                data: {
                    name: name,
                    author: author,
                    system: system
                },
                headers:{
                    token:api.user.token
                },
                success:LOG
            }).done(LOG).fail(FAIL);
        }
    }
};