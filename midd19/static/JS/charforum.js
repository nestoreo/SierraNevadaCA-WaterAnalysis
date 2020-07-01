$(document).ready(function() {
    $('like_button').on(click) function(){
        let user_id = $(this).attr('user_id')
        let preference = $(this).attr('like')
        $.ajax({
            type: "POST",
            url:'',
            data:{
                user_id:user_id, preference: preference
            }
        });




    });

});
