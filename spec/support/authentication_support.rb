module AuthenticationSupport
  def stub_api_controller_authentication!

    let(:api_user) { create(:user) }

    before do
      warden = double(:warden, user: api_user, authenticate: api_user)
      controller.stub(:env).and_return({'warden' => warden})
      controller.request.env['warden'] = warden
    end
  end
end
