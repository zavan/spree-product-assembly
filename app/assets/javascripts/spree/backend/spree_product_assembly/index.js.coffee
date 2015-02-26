#= require ./translations

$(document).ready ->
  Spree.routes.available_admin_product_parts = (productSlug) ->
    Spree.pathFor("admin/products/" + productSlug + "/parts/available")

  showErrorMessages = (xhr) ->
    response = JSON.parse(xhr.responseText)
    show_flash("error", response)

  partsTable = $("#product_parts")
  searchResultsTable = $("#search_hits")

  search_for_parts = ->
    productSlug = partsTable.data("product-slug")
    searchUrl = Spree.routes.available_admin_product_parts(productSlug)

    $.ajax
     data:
       q: $("#searchtext").val()
     dataType: 'html'
     success: (request) ->
       searchResultsTable.html(request)
       searchResultsTable.show()
     type: 'POST'
     url: searchUrl

  $("#searchtext").keypress (e) ->
    if (e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)
      search_for_parts()
      false
    else
      true

  $("#search_parts_button").click (e) ->
    e.preventDefault()
    search_for_parts()

  make_post_request = (link, post_params) ->
    spinner = $("img.spinner", link.parent())
    spinner.show()

    request = $.ajax
      type: "POST"
      url: link.attr("href")
      data: post_params
      dateType: "script"
    request.fail showErrorMessages
    request.always -> spinner.hide()

    false

  searchResultsTable.on "click", "a.add_product_part_link", (event) ->
    event.preventDefault()

    part = {}
    link = $(this)
    row = $("#" + link.data("target"))
    loadingIndicator = $("img.spinner", link.parent())
    quantityField = $('input:last', row)

    part.count = quantityField.val()

    if (row.hasClass("with-variants"))
      selectedVariantOption = $('select option:selected', row)
      part.variant_id = selectedVariantOption.val()

      if (selectedVariantOption.text() == Spree.translations.user_selectable)
        part.variant_selection_deferred = "t"
        part.variant_id = link.data("master-variant-id")

    else
      part.variant_id = $('input[name="part[id]"]', row).val()

    make_post_request(link, {assemblies_part: part})

  partsTable.on "click", "a.set_count_admin_product_part_link", ->
    params = { count :  $("input", $(this).parent().parent()).val() }
    make_post_request($(this), params)

  partsTable.on "click", "a.remove_admin_product_part_link",  ->
    make_post_request($(this), {})
