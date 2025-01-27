# frozen_string_literal: true

DiscourseAi::AiBot::EntryPoint::BOTS.each do |id, bot_username|
  UserEmail.seed do |ue|
    ue.id = id
    ue.email = "no_email_#{bot_username}"
    ue.primary = true
    ue.user_id = id
  end

  User.seed do |u|
    u.id = id
    u.name = bot_username.titleize
    u.username = UserNameSuggester.suggest(bot_username)
    u.password = SecureRandom.hex
    u.active = true
    u.admin = true
    u.moderator = true
    u.approved = true
    u.trust_level = TrustLevel[4]
  end
end
