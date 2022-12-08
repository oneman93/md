$(document).ready(function(){
    // alert('hi, lord');

  $(document).on("keyup", "#mySearch", function() {
    alert('hi');

    var value = $(this).val().toLowerCase();
    console.log('h1 length:', $('h1').length);

    $("h1").filter(function() {
        debugger;

      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
    });
  });
});

