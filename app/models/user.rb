# frozen_string_literal: true

class User < ApplicationRecord
  include UserSettings
  include UserRoles

  extend UserOmniauth
  devise :database_authenticatable, :registerable, :confirmable,
         :rememberable, :trackable, :validatable, :recoverable, :lockable,
         :omniauthable, omniauth_providers: %i[feishu gitlab google_oauth2 ldap openid_connect]

  enum role: %i[user developer admin]
  enum locale: enum_roles
  enum appearance: enum_appearances
  enum timezone: enum_timezones

  has_and_belongs_to_many :apps, dependent: :destroy
  has_many :collaborators, dependent: :destroy
  has_many :metadatum, dependent: :destroy
  has_many :providers, dependent: :destroy, class_name: 'UserProvider'

  scope :avaiables, -> (id) { where.not(id: id) }

  validates :username, presence: true
  validates :email, presence: true

  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_user_default_settings, if: :new_record?
  after_initialize :generate_user_token, if: :new_record?

  private

  def set_default_role
    self.role ||= Setting.preset_role || :user
  end

  def set_user_default_settings
    self.locale ||= Setting.site_locale
    self.appearance ||= Setting.site_appearance
    self.timezone ||= Setting.site_timezone
  end

  def generate_user_token
    self.token = Digest::MD5.hexdigest(SecureRandom.uuid)
  end
end
