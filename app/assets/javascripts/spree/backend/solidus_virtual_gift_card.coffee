window.GiftCards =
  _bindLookupGiftCard: ->
    $(document).on('submit', '#lookup-redemption-code', (event) ->
      event.preventDefault()
      window.location.href = $(this).attr('action') + '/' + $(this).find('#gift_card_redemption_code').val()
    )

  init: ->
    @_bindLookupGiftCard()

  setAdminDatepicker: () ->
    $(document).ready(() ->
      $(".giftcard-datepicker").datepicker("setDate", new Date($(".giftcard-datepicker").val().split("-")))
      $(".giftcard-datepicker").datepicker("option", "minDate", new Date())
    )


