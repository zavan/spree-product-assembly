require 'spec_helper'

describe "Checkout", type: :feature do
  let!(:country) { create(:country, :name => "United States", :states_required => true) }
  let!(:state) { create(:state, :name => "Ohio", :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let(:product) { create(:product, :name => "RoR Mug") }
  let(:variant) { create(:variant) }

  stub_authorization!

  before { product.parts.push variant }

  shared_context "purchases product with part included" do
    before do
      add_product_to_cart
      click_button "Checkout"

      fill_in "order_email", :with => "ryan@spreecommerce.com"
      fill_in_address

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("delivery"))
      page.should have_content(variant.product.name)

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("payment"))

      click_button "Save and Continue"
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      page.should have_content(variant.product.name)
    end
  end

  context "backend order shipments UI", js: true do

    context "ordering only the product assembly" do
      include_context "purchases product with part included"

      it "views parts bundled as well" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end

    context "ordering assembly and the part as individual sale" do
      before do
        visit spree.root_path
        click_link variant.product.name
        click_button "add-to-cart-button"
      end
      include_context "purchases product with part included"

      it "views parts bundled and not" do
        visit spree.admin_orders_path
        click_on Spree::Order.last.number

        page.should have_content(variant.product.name)
      end
    end

  end

  context "when a part allows User to select any variant" do
    xit "does not show parts that are out-of-stock" do
    end

    xit "does not allow selection of variants that are out-of-stock" do

    end

    it "shows the part the User selected at all stages of checkout" do
      bundle = create(:product)
      red_option = create(:option_value, presentation: "Red")
      blue_option = create(:option_value, presentation: "Blue")

      option_type = create(:option_type, presentation: "Color", name: "color")
      option_type.option_values = [red_option, blue_option]

      part = create(:product, option_types: [option_type], can_be_part: true)

      create(:variant, product: part) do |variant|
        variant.option_values = [red_option]
      end
      create(:variant, product: part) do |variant|
        variant.option_values = [blue_option]
      end

      create(:assemblies_part,
        assembly: bundle,
        part_id: part.master.id,
        variant_selection_deferred: true
      )

      visit spree.root_path
      click_link bundle.name

      select "Blue", from: "Color"
      click_button "add-to-cart-button"

      click_button "Checkout"

      fill_in "order_email", :with => "ryan@spreecommerce.com"
      fill_in_address

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("delivery"))
      page.should have_content(variant.product.name)
      page.should have_content("Blue")

      click_button "Save and Continue"
      expect(current_path).to eql(spree.checkout_state_path("payment"))
      page.should have_content("Blue")

      click_button "Save and Continue"
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      page.should have_content(variant.product.name)
      page.should have_content("Blue")
    end
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", :with => "Ryan"
    fill_in "#{address}_lastname", :with => "Bigg"
    fill_in "#{address}_address1", :with => "143 Swan Street"
    fill_in "#{address}_city", :with => "Richmond"
    select "Ohio", :from => "#{address}_state_id"
    fill_in "#{address}_zipcode", :with => "12345"
    fill_in "#{address}_phone", :with => "(555) 555-5555"
  end

  def add_product_to_cart
    visit spree.root_path
    click_link product.name
    click_button "add-to-cart-button"
  end
end
