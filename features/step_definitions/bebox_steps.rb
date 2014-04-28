When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

When /^I want to create a new project called "([^"]*)"$/ do |project_name|
  @app_name = 'bebox'
  step %(I run `#{@app_name}  new #{project_name}`)
end

# Add more step definitions here
