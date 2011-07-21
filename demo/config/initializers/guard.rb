Demo::Application.config.guard.register_flavor(:domain) do |controller, group|
  if controller.respond_to?(:current_user)
    user = controller.send :current_user
    user.domains_for_group(group).collect{ |d| d.name } if group != :*
  end
end

Demo::Application.config.guard.register_flavor(:locale) do |controller, group|
  if controller.respond_to?(:current_user)
    user = controller.send :current_user
    map = {
      "admin3:translators" => ["*"],
      "translator1:translators" => ["de"],
      "translator2:translators" => ["fr"]
    }
    map[ user.name + ":" + group.to_s] || []
  end
end
