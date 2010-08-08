Before ('@clean') do
	Link.destroy
	link = Link.new(
		:url=> "www.google.com",
		:title=> "google",
		:body=> "hello"
	)
	link.save
	link = Link.new(
		:url=> "www.yahoo.com",
		:title=> "yahoo",
		:body=> "hello"
	)
	link.save
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