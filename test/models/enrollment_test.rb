require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  test "belongs to a client and a provider" do
    enrollment = enrollments(:shared_client_premium)

    assert_equal clients(:client_with_two_providers), enrollment.client
    assert_equal providers(:provider_with_two_clients), enrollment.provider
  end

  test "the plan is per client-provider pair, not per client" do
    assert_equal "premium", enrollments(:shared_client_premium).plan_type
    assert_equal "basic", enrollments(:shared_client_basic).plan_type
  end

  test "a client cannot be enrolled with the same provider twice" do
    assert_raises ActiveRecord::RecordNotUnique do
      Enrollment.create!(client: clients(:client_with_two_providers),
                         provider: providers(:provider_with_two_clients),
                         plan_type: "basic")
    end
  end
end
