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

  test "accepts the two documented plans" do
    assert_predicate build_enrollment(plan_type: "basic"), :valid?
    assert_predicate build_enrollment(plan_type: "premium"), :valid?
  end

  test "rejects a plan outside the allowed values" do
    enrollment = build_enrollment(plan_type: "banana")

    assert_not enrollment.valid?
    assert_includes enrollment.errors[:plan_type], "is not included in the list"
  end

  test "rejects a blank plan" do
    [ nil, "" ].each do |blank|
      enrollment = build_enrollment(plan_type: blank)

      assert_not enrollment.valid?, "expected #{blank.inspect} to be rejected"
      assert_includes enrollment.errors[:plan_type], "can't be blank"
    end
  end

  test "does not fall back to a default plan" do
    # str_enum assigns values.first unless default: nil is passed. A forgotten
    # plan should fail loudly rather than quietly become basic.
    assert_nil Enrollment.new.plan_type
  end

  private
    # client_with_one_provider and provider_with_one_client are not enrolled
    # with each other in the fixtures, so this pair is free to validate against.
    def build_enrollment(attributes)
      Enrollment.new({ client: clients(:client_with_one_provider),
                       provider: providers(:provider_with_one_client) }.merge(attributes))
    end
end
