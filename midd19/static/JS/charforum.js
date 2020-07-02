<<<<<<< HEAD
/*$(document).ready(function() {
    $(document).on('submit',"#like_form", function(){
=======
$(document).ready(function() {
    $('like_button').on("click", function(){
        let user_id = $(this).attr('user_id')
        let preference = $(this).attr('like')
>>>>>>> 31953baffaa40ade514d24c15cd21c017c1bfc4b
        $.ajax({
            type: "POST",
            url:'',
            data:{
<<<<<<< HEAD
                user_id: $('#like_input').val,
            }
            sucess: function(){

            }
        });
=======
                user_id:user_id, preference: preference
            }
        });




>>>>>>> 31953baffaa40ade514d24c15cd21c017c1bfc4b
    });

});
*/
