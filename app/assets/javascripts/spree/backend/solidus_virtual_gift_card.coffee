window.GiftCards =
  setAdminDatepicker: () ->
    $(document).ready(() ->
      if $(".giftcard-datepicker").val()
        $(".giftcard-datepicker").datepicker("setDate", new Date($(".giftcard-datepicker").val().split("-")))
        $(".giftcard-datepicker").datepicker("option", "minDate", new Date())
    )


