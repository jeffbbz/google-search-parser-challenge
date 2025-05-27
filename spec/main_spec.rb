require_relative '../lib/main.rb'

RSpec.describe Greetings do
  it 'greets you' do
    expect(Greetings.hello_world).to eq("Hello, world!")
  end
end
