After ('@clean') do
		Link.destroy
end

Then /^(?:|I )should see a link with url "([^\"]*)"(?: within "([^\"]*)")?$/ do |url, selector|
  with_scope(selector) do
    if page.respond_to? :should
      page.should have_xpath("//a[@href='#{url}']")
    else
      assert page.has_xpath?("//a[@href='#{url}']")
    end
  end
end