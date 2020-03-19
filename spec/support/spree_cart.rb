def update_form
  if Spree.version.to_f < 4.1
    click_button "update-button"
  else
    page.execute_script("$('form#update-cart').submit()")
  end
end

def container
  if Spree.version.to_f < 4.1
    find_all("#cart-detail tbody tr:first-child").first
  else
    find_all("#cart-detail .shopping-cart-item").first
  end
end

def add_to_cart
  click_button "add-to-cart-button"
  if Spree.version.to_f < 4.1
    wait_for_condition do
      expect(page).to have_content(Spree.t(:cart))
    end
  else
    expect(page).to have_content(Spree.t(:added_to_cart))
    visit spree.cart_path
  end
end
