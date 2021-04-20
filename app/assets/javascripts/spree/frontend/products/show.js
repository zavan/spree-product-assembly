Spree.ready(function(){
  if ($('.assemblies_variant').length) {
    $('.assemblies_variant').first().show();

    $('[name="variant_id"]').on('click', function(){
      $('.assemblies_variant').hide();
      $('.assemblies_for_variant_' + $(this).val()).show();
    });
  }

  var calculateTotal = function(scope) {
    var total = 0;
    scope.find('.quantity-select-value').each(function(_i, item) {
      total += parseInt($(item).val());
    });

    return total;
  };

  var isUserSelectable = $('.assemblies_variant input[type=number].quantity-select-value').length > 0;

  if (isUserSelectable) {
    var $addToCartButton = $('.add-to-cart-button');

    var handleQuantityChange = function() {
      var $table = $('.assemblies_variant');
      var $message = $table.siblings('.parts-message');

      var min = parseInt($table.data('min'));
      var max = parseInt($table.data('max'));

      // Wait for spree JS to actually change the input value.
      setTimeout(function() {
        var total = calculateTotal($table);

        if (max > 0 && total > max) {
          $addToCartButton.prop('disabled', true);
          $message.text('You have selected ' + total + ' items, please remove at least ' + (total - max));
        } else if (total < min) {
          $addToCartButton.prop('disabled', true);
          $message.text('You have selected ' + total + ' items, please select at least ' + (min - total) + ' more');
        } else {
          $addToCartButton.prop('disabled', false);
          $message.text('You have selected ' + total + ' items');
        }

        $message.show();
      }, 50);
    };

    handleQuantityChange();

    $('.assemblies_variant .quantity-select-value').on('change', handleQuantityChange);
    $('.assemblies_variant .quantity-select-decrease').on('click', handleQuantityChange);
    $('.assemblies_variant .quantity-select-increase').on('click', handleQuantityChange);
  }
});
