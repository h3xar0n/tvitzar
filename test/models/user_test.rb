require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Example User", email:"example@user.com", 
                     password: "foobar", password_confirmation: "foobar")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "    "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "    "
    assert_not @user.valid?
  end

  test "name shouldn't be too long" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "email shouldn't be too long" do
    @user.name = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[ user@example.com 
                          USER@foo.com 
                          A_sausage-man@boo.org.com 
                          money@sasuage.jp 
                          alice+bob@aron.cn ]
    valid_addresses.each do |valid_addresses|
      @user.email = valid_addresses
      assert @user.valid?, "Address #{valid_addresses.inspect} should be valid."
    end
  end

  test "email validation should reject invalid email addresses" do
    invalid_addresses = %w[ user@example,com 
                            user_at_foo.org 
                            user@example.
                            foo@bar_baz.com ]
    invalid_addresses.each do |invalid_addresses|
      @user.email = invalid_addresses
      assert_not @user.valid?, 
        "Address #{invalid_addresses.inspect} should be invalid."
    end
  end

  test "email address should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email addresses should be saved as lower-case" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end  

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end

  test "associated microposts should be destroyed" do
    @user.save
    @user.microposts.create!(content: "Lorem ipsum")
    assert_difference 'Micropost.count', -1 do
      @user.destroy
    end
  end

  test "should follow and unfollow a user" do
    aron = users(:aron)
    archer  = users(:archer)
    assert_not aron.following?(archer)
    aron.follow(archer)
    assert aron.following?(archer)
    assert archer.followers.include?(aron)
    aron.unfollow(archer)
    assert_not aron.following?(archer)
  end

  test "feed should have the right posts" do
    aron = users(:aron)
    archer  = users(:archer)
    lana    = users(:lana)
    # Posts from followed user
    lana.microposts.each do |post_following|
      assert aron.feed.include?(post_following)
    end
    # Posts from self
    aron.microposts.each do |post_self|
      assert aron.feed.include?(post_self)
    end
    # Posts from unfollowed user
    archer.microposts.each do |post_unfollowed|
      assert_not aron.feed.include?(post_unfollowed)
    end
  end
end
