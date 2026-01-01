# A2UI Rails Engine Boundaries

## Current State

The A2UI codebase is currently mixed into a Rails application:

```
lib/a2ui/                    # Core types, signatures, modules (pure Ruby)
app/controllers/a2ui/        # Rails controllers
app/components/a2ui/         # ViewComponents
app/views/a2ui/              # View partials
config/initializers/         # Inflector rules (A2UI acronym)
```

## Engine Architecture

### Layer 1: Core Library (a2ui gem)
Pure Ruby, no Rails dependencies. Can be used standalone.

```
lib/a2ui/
├── version.rb
├── types.rb                 # T::Struct, T::Enum definitions
├── types/                   # Individual type files
├── signatures.rb            # DSPy signatures
├── signatures/              # Individual signature files
└── modules.rb               # DSPy modules (Surface, SurfaceManager, etc.)
```

### Layer 2: Rails Engine (a2ui-rails gem)
Rails integration that depends on Layer 1.

```
lib/a2ui/
├── engine.rb                # Rails::Engine subclass
└── railtie.rb               # Railtie for configuration

app/
├── controllers/a2ui/
│   ├── application_controller.rb  # Base controller
│   ├── surfaces_controller.rb
│   └── actions_controller.rb
├── components/a2ui/
│   └── components/               # ViewComponents
├── views/a2ui/
│   ├── _surface.html.erb
│   └── _data.html.erb
└── helpers/a2ui/
    └── component_helper.rb       # View helpers

config/
└── routes.rb                     # Engine routes
```

## Engine Features

### 1. Mountable Routes
```ruby
# Host app config/routes.rb
Rails.application.routes.draw do
  mount A2UI::Engine => '/a2ui'
end
```

### 2. Automatic Inflector Configuration
Engine automatically configures `A2UI` acronym.

### 3. Asset Pipeline Integration
- CSS for default component styling
- JavaScript for Turbo/Stimulus integration

### 4. ViewComponent Integration
Components automatically available when engine mounted.

### 5. Configuration
```ruby
A2UI.configure do |config|
  config.default_lm = 'anthropic/claude-sonnet'
  config.cache_store = Rails.cache
end
```

## Implementation Plan

1. Create `lib/a2ui/engine.rb` with Engine class
2. Create `lib/a2ui/railtie.rb` for non-engine Rails apps
3. Move routes to engine `config/routes.rb`
4. Create base controller for engine
5. Add configuration module
6. Set up asset paths

## Boundaries

### What stays in lib/a2ui/ (Core)
- All T::Struct and T::Enum types
- All DSPy signatures
- All DSPy modules
- Surface and SurfaceManager
- No Rails dependencies

### What goes in Engine
- Controllers
- ViewComponents
- View templates
- Routes
- Initializers (inflector, etc.)
- Assets (CSS, JS)
- Generators
