# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  email                  :string(255)
#  username               :string(255)
#  ip_address             :string(255)
#  guid                   :string(255)
#  banned                 :boolean          default(FALSE)
#  created_at             :datetime
#  updated_at             :datetime
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  avatar                 :string(255)
#  bio                    :text
#

require 'file_size_validator'

class User < ActiveRecord::Base
  include UserDetails
  mount_uploader :avatar, UserAvatarUploader
  validates :avatar, file_size: { maximum: 1.megabytes.to_i }
  validates :username, :email, presence: true, uniqueness: true
  validate :check_parameterization_of_username, on: :create

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_many :discussions, dependent: :nullify
  has_many :discussion_comments, dependent: :nullify

  def avatar_url the_guid=nil
    the_guid ||= self.guid

    if avatar.present?
      avatar.thumb.url
    elsif the_guid == nil
      avatar.default_url
    else
      ASSET_BUCKET.objects["identicons/#{the_guid}-pic.jpg"].public_url
    end
  end

  def can_contribute?
    logged_in? || AppSettings.first.guest_posting == true
  end

  def guest?
    username == 'Guest'
  end

  def logged_in?
    !guest?
  end

  def username
    super || 'Guest'
  end

  def discussion_count
    discussions.size
  end

  def comment_count
    discussion_comments.size
  end

  private

  def check_parameterization_of_username
    pending_username = username.titleize.downcase
    query = User.arel_table

    if User.where(username: username.parameterize).any? || User.where(query[:username].matches(pending_username)).any?
      errors.add(:username, 'has already been taken')
    end
  end
end