require_relative 'support/server'
require_relative 'support/model'

RSpec.describe "server with AJAX", type: :feature, js: true do
  before do
    Capybara.app = AjaxServer
    AjaxServer.should_return_from_ajax = false
    @expected_message = "foobar"
    TestValue.create! content: @expected_message
  end

  it "waits for AJAX from jQuery" do
    visit "/ajax/jquery"
    expect(page).to have_content("Hello")
    click_link "Do AJAX"
    Thread.fork do
      sleep 0.5
      AjaxServer.should_return_from_ajax = true
    end
    expect(find(".message").text).not_to eq(@expected_message)
    TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)
    expect(find(".message").text).to eq(@expected_message)
  end

  it "waits for AJAX from Angular" do
    visit "/ajax/angular"
    expect(page).to have_content("Hello")
    click_link "Do AJAX"
    Thread.fork do
      sleep 0.5
      AjaxServer.should_return_from_ajax = true
    end
    expect(find(".message").text).not_to eq(@expected_message)
    TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)
    expect(find(".message").text).to eq(@expected_message)
  end

  context "mixed in" do
    include TransactionalCapybara::AjaxHelpers
    it "provides wait_for_ajax helper" do
      visit "/ajax/jquery"
      expect(page).to have_content("Hello")
      click_link "Do AJAX"
      Thread.fork do
        sleep 0.5
        AjaxServer.should_return_from_ajax = true
      end
      expect(find(".message").text).not_to eq(@expected_message)
      wait_for_ajax
      expect(find(".message").text).to eq(@expected_message)
    end
  end

  context "after hook", check_result_after: true do
    it "automatically waits for AJAX" do
      visit "/ajax/jquery"
      expect(page).to have_content("Hello")
      click_link "Do AJAX"
      Thread.fork do
        sleep 0.5
        AjaxServer.should_return_from_ajax = true
      end
      expect(find(".message").text).not_to eq(@expected_message)
    end
  end

  it "waits on all sessions" do
    using_session :foo do
      visit "/ajax/jquery"
      expect(page).to have_content("Hello")
      click_link "Do AJAX"
    end

    using_session :bar do
      visit "/boring_page"
      expect(page).to have_content("Hi")
    end

    Thread.fork do
      sleep 0.5
      AjaxServer.should_return_from_ajax = true
    end
    TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)

    using_session :foo do
      expect(find(".message").text).to eq(@expected_message)
    end

    AjaxServer.should_return_from_ajax = false

    using_session :bar do
      visit "/ajax/jquery"
      expect(page).to have_content("Hello")
      click_link "Do AJAX"
    end

    Thread.fork do
      sleep 0.5
      AjaxServer.should_return_from_ajax = true
    end
    TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)

    using_session :bar do
      expect(find(".message").text).to eq(@expected_message)
    end
  end
end
