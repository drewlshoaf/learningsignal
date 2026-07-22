require "rails_helper"

RSpec.describe "Authentication" do
  it "redirects guests to sign in" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "signs a teacher in with password authentication" do
    scenario = build_learning_scenario

    post session_path, params: {
      email_address: scenario.fetch(:teacher).email_address,
      password: "test-password"
    }

    expect(response).to redirect_to(root_url)
    follow_redirect!
    expect(response.body).to include("Academic signals")
    expect(response.body).to include("Maya R.")
  end
end
