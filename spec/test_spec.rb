RSpec.describe "Whitespace" do
  it "Helloworld" do
    output = `ruby lib/whitespace.rb spec/helloworld.ws`
    expect(output).to eq "Hello, world of spaces!\r\n"
  end
end
