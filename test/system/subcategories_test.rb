require "application_system_test_case"

class SubcategoriesTest < ApplicationSystemTestCase
  setup do
    @subcategory = subcategories(:one)
  end

  test "visiting the index" do
    visit subcategories_url
    assert_selector "h1", text: "Subcategories"
  end

  test "should create subcategory" do
    visit subcategories_url
    click_on "New subcategory"

    fill_in "Category", with: @subcategory.category_id
    check "Hidden" if @subcategory.hidden
    fill_in "Name", with: @subcategory.name
    click_on "Create Subcategory"

    assert_text "Subcategory was successfully created"
    click_on "Back"
  end

  test "should update Subcategory" do
    visit subcategory_url(@subcategory)
    click_on "Edit this subcategory", match: :first

    fill_in "Category", with: @subcategory.category_id
    check "Hidden" if @subcategory.hidden
    fill_in "Name", with: @subcategory.name
    click_on "Update Subcategory"

    assert_text "Subcategory was successfully updated"
    click_on "Back"
  end

  test "should destroy Subcategory" do
    visit subcategory_url(@subcategory)
    click_on "Destroy this subcategory", match: :first

    assert_text "Subcategory was successfully destroyed"
  end
end
