Dry::Rails.container do
  config.component_dirs.add "app/modules"

  config.features = %i[
    controller_helpers
  ]
end
