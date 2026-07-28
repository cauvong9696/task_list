require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and password" do
    user = User.new(email: "new@example.com", password: "secret123")
    assert user.valid?
  end

  test "requires a unique email (case-insensitive)" do
    user = User.new(email: users(:alice).email.upcase, password: "secret123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "normalizes email to lowercase and trims it" do
    user = User.create!(email: "  MixedCase@Example.com  ", password: "secret123")
    assert_equal "mixedcase@example.com", user.email
  end

  test "rejects an invalid email format" do
    user = User.new(email: "not-an-email", password: "secret123")
    assert_not user.valid?
  end

  test "authenticates with the correct password" do
    user = User.create!(email: "auth@example.com", password: "secret123")
    assert user.authenticate("secret123")
    assert_not user.authenticate("wrong")
  end

  test "is not an admin by default" do
    user = User.create!(email: "regular@example.com", password: "secret123")
    assert_not user.admin?
  end
end
