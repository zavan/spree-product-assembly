RSpec.feature "Adding items to the cart", type: :feature do
  context "when adding a bundle to the cart" do
    context "when none of the bundle items are packs or have options" do
      scenario "the cart lists the contents of the bundle" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)
        shirt = create(:product_in_stock, name: "Shirt",
                                          sku: "SHIRT",
                                          can_be_part: true)

        add_part_to_bundle(bundle.master, keychain.master)
        add_part_to_bundle(bundle.master, shirt.master)

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail") do
          within("tbody tr:first-child") do
            expect(page).to have_content(bundle.name)
            expect(page).to have_css("input[value='1']")
            expect(page).to have_content("(1) Keychain (KEYCHAIN)")
            expect(page).to have_content("(1) Shirt (SHIRT)")
          end
        end
      end
    end

    context "when one of the variants is a pack" do
      scenario "the cart displays the same quantity for part line items" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)
        _shirt, shirts_by_size = create_bundle_product_with_options(
          name: "Shirt",
          sku: "SHIRT",
          option_type: "Size",
          option_values: ["Small"]
        )

        add_part_to_bundle(bundle.master, keychain.master, count: 2)
        add_part_to_bundle(bundle.master, shirts_by_size["small"])

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='1']")
          expect(page).to have_content("(2) Keychain (KEYCHAIN)")
          expect(page).to have_content("(1) Shirt (Size: Small) (SHIRT-SMALL)")
        end
      end

      context "when ordering more than one of the bundle" do
        scenario "the part quantity is multiplied by the bundle quantity" do
          bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

          keychain = create(:product_in_stock, name: "Keychain",
                                               sku: "KEYCHAIN",
                                               can_be_part: true)
          shirt = create(:product_in_stock, name: "Shirt",
                                            sku: "SHIRT",
                                            can_be_part: true)

          add_part_to_bundle(bundle.master, keychain.master, count: 2)
          add_part_to_bundle(bundle.master, shirt.master)

          visit spree.product_path(bundle)

          fill_in "quantity", with: 2

          click_button "add-to-cart-button"

          within("#cart-detail tbody tr:first-child") do
            expect(page).to have_content(bundle.name)
            expect(page).to have_css("input[value='2']")
            expect(page).to have_content("(4) Keychain (KEYCHAIN)")
            expect(page).to have_content("(2) Shirt (SHIRT)")
          end
        end
      end
    end

    context "when a bundle items has a variant (that is not user-selectable)" do
      scenario "the cart includes the variant when listing items bundle items" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)
        _shirt, shirts_by_size = create_bundle_product_with_options(
          name: "Shirt",
          sku: "SHIRT",
          option_type: "Size",
          option_values: ["Small"]
        )

        add_part_to_bundle(bundle.master, keychain.master)
        add_part_to_bundle(bundle.master, shirts_by_size["small"])

        visit spree.product_path(bundle)

        click_button "add-to-cart-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='1']")
          expect(page).to have_content("(1) Keychain (KEYCHAIN)")
          expect(page).to have_content("(1) Shirt (Size: Small) (SHIRT-SMALL)")
        end
      end
    end

    context "when one of the bundle items has a user-selectable variant", js: true do
      scenario "the cart includes the variant when listing bundle items" do
        bundle = create(:product_in_stock, name: "Bundle", sku: "BUNDLE")

        keychain = create(:product_in_stock, name: "Keychain",
                                             sku: "KEYCHAIN",
                                             can_be_part: true)

        shirt = bundled_product_from_options(
          name: "Shirt", option_type: "Size", option_values: ["Small", "Medium"]
        )

        add_part_to_bundle(bundle.master, keychain.master, count: 1)
        add_part_to_bundle(
          bundle.master,
          shirt.master,
          count: 1,
          variant_selection_deferred: true
        )

        visit spree.product_path(bundle)

        select 'Size: Medium', from: 'Variant'

        click_button "add-to-cart-button"

        within("#cart-detail tbody tr:first-child") do
          expect(page).to have_content(bundle.name)
          expect(page).to have_css("input[value='1']")
          expect(page).to have_content("(1) Keychain (KEYCHAIN)")
          expect(page).to(
            have_content("(1) Shirt (Size: Medium) (SHIRT-MEDIUM)")
          )
        end
      end
    end

    context "when both of the bundle items have a user-selectable variant", js: true do
      let(:bundle) { create(:product_in_stock, name: "Bundle", sku: "BUNDLE") }
      let(:keychain) do
        create(:product_in_stock, name: "Keychain",
                                  sku: "KEYCHAIN",
                                  can_be_part: true)
      end

      let(:shirt) do
        bundled_product_from_options(
          name: "Shirt", option_type: "Size", option_values: ["Large", "XL"]
        )
      end
      let(:hat) do
        bundled_product_from_options(
          name: "Hat", option_type: "Color", option_values: ["Red", "Blue"]
        )
      end

      before do
        add_part_to_bundle(
          bundle.master,
          keychain.master,
          count: 1
        )

        add_part_to_bundle(
          bundle.master,
          shirt.master,
          variant_selection_deferred: true
        )

        add_part_to_bundle(
          bundle.master,
          hat.master,
          variant_selection_deferred: true
        )
      end

      context "and the user selects differing variants from the existing line item" do
        it "contains 2 line items of the same SKU with differing variants " do
          add_item_to_cart(size: "Large", color: "Red")
          add_item_to_cart(size: "XL", color: "Blue")

          within all("#cart-detail .line-item")[0] do
            expect(page).to have_content(bundle.name)
            expect(page).to have_css("input[value='1']")
            expect(page).to(
              have_content("(1) Keychain (KEYCHAIN)")
            )
            expect(page).to(
              have_content("(1) Shirt (Size: Large) (SHIRT-LARGE)")
            )
            expect(page).to(
              have_content("(1) Hat (Color: Red) (HAT-RED)")
            )
          end

          within all("#cart-detail .line-item")[1] do
            expect(page).to have_content(bundle.name)
            expect(page).to have_css("input[value='1']")
            expect(page).to(
              have_content("(1) Keychain (KEYCHAIN)")
            )
            expect(page).to(
              have_content("(1) Shirt (Size: XL) (SHIRT-XL)")
            )
            expect(page).to(
              have_content("(1) Hat (Color: Blue) (HAT-BLUE)")
            )
          end
        end
      end

      context "and the user selects the same variants as the existing line item" do
        it "contains 1 line item with incremented variants and quantities" do
          2.times { add_item_to_cart(size: "Large", color: "Red") }

          within "#cart-detail .line-item" do
            expect(page).to have_content(bundle.name)
            expect(page).to have_css("input[value='2']")
            expect(page).to(
              have_content("(2) Keychain (KEYCHAIN)")
            )
            expect(page).to(
              have_content("(2) Shirt (Size: Large) (SHIRT-LARGE)")
            )
            expect(page).to(
              have_content("(2) Hat (Color: Red) (HAT-RED)")
            )
          end
        end
      end
    end
  end

  def add_item_to_cart(args)
    visit spree.product_path(bundle)

    select "Size: #{args[:size]}", from: "options_selected_variants_3"
    select "Color: #{args[:color]}", from: "options_selected_variants_6"
    click_button "add-to-cart-button"
  end

  def bundled_product_from_options(args)
    args[:sku] ||= args[:name].parameterize.upcase

    product, _product_variants = create_bundle_product_with_options(args)

    product
  end

  def create_bundle_product_with_options(args)
    option_type_presentation = args.fetch(:option_type)
    option_value_presentations = args.fetch(:option_values)
    option_values = option_value_presentations.map do |presentation|
      create(:option_value, presentation: presentation)
    end
    option_type = create(:option_type,
                         presentation: option_type_presentation,
                         name: option_type_presentation.downcase,
                         option_values: option_values)
    product_attributes = args.slice(:name, :sku).merge(
      option_types: [option_type],
      can_be_part: true
    )
    product = create(:product, product_attributes)

    variants = variants_by_option(product, option_values)

    [product, variants]
  end

  def variants_by_option(product, option_values)
    option_values.each_with_object({}) do |value, hash|
      hash[value.presentation.downcase] = create(
        :variant_in_stock,
        product: product,
        sku: "#{product.sku}-#{value.presentation.upcase}",
        option_values: [value]
      )
    end
  end

  def add_part_to_bundle(bundle_master, variant, options = {})
    attributes = options.reverse_merge(
      assembly_id: bundle_master.id,
      part_id: variant.id,
    )
    create(:assemblies_part, attributes).tap do |_part|
      bundle_master.product.reload
    end
  end
end
