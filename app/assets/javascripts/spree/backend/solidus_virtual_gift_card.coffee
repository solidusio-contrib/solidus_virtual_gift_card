window.GiftCards =
  setAdminDatepicker: () ->
    $(document).ready(() ->
      $(".giftcard-datepicker").datepicker("setDate", new Date($(".giftcard-datepicker").val().split("-")))
      $(".giftcard-datepicker").datepicker("option", "minDate", new Date())
    )


