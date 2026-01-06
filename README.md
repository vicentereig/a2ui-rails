# A2UI Rails

A Ruby port of [Google's A2UI](https://github.com/google/A2UI) (Agent-to-User Interface) for Rails, using Turbo Streams and DSPy.rb for LLM-driven UI generation.

> **Status**: Early development. APIs will change.

![Daily Briefing Demo](docs/images/daily-briefing.png)

*AI-generated health briefing from Garmin data using DSPy.rb signatures*

## What is A2UI?

A2UI lets AI agents generate rich, interactive UIs by shipping **data and UI descriptions together** as structured output, rather than executable code. The client maintains a catalog of trusted components that the agent references by type.

This port maps A2UI concepts to Rails + Turbo:

| A2UI | Rails + Turbo |
|------|---------------|
| Surface | `<turbo-frame>` |
| `surfaceUpdate` | `<turbo-stream>` |
| `dataModelUpdate` | Stimulus controller values |
| Component catalog | ViewComponent library |
| JSON adjacency list | Rendered HTML fragments |

## DSPy Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           A2UI DSPy Pipelines                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ CREATE SURFACE                                                       │   │
│  │                                                                      │   │
│  │   "Create a booking form"  ───▶  GenerateUI (ChainOfThought)        │   │
│  │         + surface_id                      │                          │   │
│  │         + available_data           ┌──────┴──────┐                   │   │
│  │                                    ▼             ▼                   │   │
│  │                              root_id      components[]               │   │
│  │                              "form-1"     [Column, TextField,        │   │
│  │                                            TextField, Button]        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ UPDATE SURFACE                                                       │   │
│  │                                                                      │   │
│  │   "Add phone field"        ───▶  UpdateUI (ChainOfThought)          │   │
│  │         + current_components              │                          │   │
│  │         + current_data             ┌──────┴──────┐                   │   │
│  │                                    ▼             ▼                   │   │
│  │                              streams[]    new_components[]           │   │
│  │                              [{action:    [TextFieldComponent]       │   │
│  │                                "after",                              │   │
│  │                                target:                               │   │
│  │                                "email"}]                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ HANDLE ACTION                                                        │   │
│  │                                                                      │   │
│  │   UserAction{name,context} ───▶  HandleAction (ChainOfThought)      │   │
│  │         + business_rules                  │                          │   │
│  │         + current_data            ┌───────┼───────┐                  │   │
│  │                                   ▼       ▼       ▼                  │   │
│  │                            response   streams  data_updates          │   │
│  │                            _type      []       [{path: "/booking",   │   │
│  │                            :update_ui          entries: [...]}]      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How It Works

**Signals (Inputs):**
- `request` — Natural language describing what to build/change
- `available_data` / `current_data` — JSON data model the UI binds to
- `current_components` — Existing component tree for incremental updates
- `business_rules` — Domain constraints for action handling

**Decisions (LLM Reasoning via ChainOfThought):**
1. **Component Selection** — Which component types fit the request?
2. **Layout Structure** — How to arrange components (Row vs Column, nesting)?
3. **Data Binding** — Which JSON Pointer paths connect to which fields?
4. **Action Mapping** — What context to capture when buttons are clicked?
5. **Stream Operations** — For updates: append, replace, or remove?

**Outputs (Structured):**
- `components[]` — Flat adjacency list of typed component structs
- `root_id` — Entry point for rendering the tree
- `streams[]` — Turbo Stream operations (action + target + content)
- `data_updates[]` — Mutations to apply to the data model

The LLM never generates code—only typed data structures that map to trusted ViewComponents.

## Installation

Add to your Gemfile:

```ruby
gem 'dspy', '~> 0.34'
gem 'sorbet-runtime'

# Choose your LLM provider:
gem 'dspy-openai'    # OpenAI, OpenRouter, Ollama
# gem 'dspy-anthropic' # Claude
# gem 'dspy-gemini'    # Gemini
```

### Quick Setup with Generators

```bash
# Install A2UI (creates initializer, routes, CSS)
rails generate a2_u_i:install

# Create a new surface
rails generate a2_u_i:surface Dashboard
```

### Manual Setup

Copy the `lib/a2ui/` and `app/` directories to your Rails app.

Configure DSPy in an initializer:

```ruby
# config/initializers/dspy.rb
DSPy.configure do |c|
  c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV['OPENAI_API_KEY'])
end
```

Configure A2UI (optional):

```ruby
# config/initializers/a2ui.rb
A2UI.configure do |config|
  config.default_model = 'anthropic/claude-sonnet-4-20250514'
  config.debug = Rails.env.development?
end
```

## Quick Start

### Generate UI from Natural Language

```ruby
# Define typed data models
class BookingData < T::Struct
  const :guests, Integer, default: 2
  const :date, T.nilable(String)
  const :email, T.nilable(String)
end

manager = A2UI::SurfaceManager.new

# Create a surface with typed data
surface = manager.create(
  surface_id: 'booking-form',
  request: 'Create a booking form with guest count, date picker, and submit button',
  data: BookingData.new(guests: 2)
)

# For surfaces without initial data
surface = manager.create(
  surface_id: 'welcome',
  request: 'Create a welcome message',
  data: A2UI::EmptyData.new
)

# Render in your view
render partial: 'a2ui/surface', locals: { surface: surface }
```

### Handle User Actions

```ruby
# Define typed context for the action
class SubmitBookingContext < T::Struct
  const :guests, Integer
  const :date, String
end

action = A2UI::UserAction.new(
  name: 'submit_booking',
  surface_id: 'booking-form',
  source_id: 'submit-btn',
  context: SubmitBookingContext.new(guests: 3, date: '2025-01-15')
)

result = manager.handle_action(
  action: action,
  business_rules: 'Maximum 10 guests per booking'
)

# result.response_type => A2UI::ActionResponseType::UpdateUI
# result.streams => [A2UI::StreamOp, ...]
# result.components => [A2UI::Component, ...]
```

### Update Existing UI

```ruby
result = manager.update(
  surface_id: 'booking-form',
  request: 'Add a phone number field after the email'
)

# Returns Turbo Stream operations to apply
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Rails App                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DSPy Signatures          DSPy Modules         Controllers   │
│  ┌─────────────┐         ┌─────────────┐      ┌───────────┐ │
│  │ GenerateUI  │────────▶│ UIGenerator │─────▶│ Surfaces  │ │
│  │ UpdateUI    │         │ UIUpdater   │      │ Actions   │ │
│  │ HandleAction│         │ ActionHndlr │      └───────────┘ │
│  └─────────────┘         └─────────────┘            │       │
│         │                       │                   │       │
│         ▼                       ▼                   ▼       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              A2UI::Components::Renderer                 ││
│  │         Maps Component structs → ViewComponents         ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 Turbo Streams / Frames                  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Core Concepts

### Signatures (DSPy)

Type-safe interfaces for LLM calls using Sorbet types:

```ruby
class A2UI::GenerateUI < DSPy::Signature
  description 'Generate UI components from natural language.'

  input do
    const :request, String
    const :surface_id, String
    const :available_data, String, default: '{}'
  end

  output do
    const :root_id, String
    const :components, T::Array[Component]  # Union type
    const :initial_data, T::Array[DataUpdate], default: []
  end
end
```

### Union Types

Components and values use discriminated unions for type safety:

```ruby
# Value is either literal or a path reference
A2UI::Value = T.any(A2UI::LiteralValue, A2UI::PathReference)

# Children are either explicit IDs or data-driven
A2UI::Children = T.any(A2UI::ExplicitChildren, A2UI::DataDrivenChildren)

# Component is a union of all component types
A2UI::Component = T.any(
  A2UI::TextComponent,
  A2UI::ButtonComponent,
  A2UI::TextFieldComponent,
  A2UI::RowComponent,
  A2UI::ColumnComponent,
  # ... 13 total
)
```

DSPy automatically handles `_type` discrimination in LLM responses.

### Type-Safe Data

A2UI uses the same type coercion pattern as DSPy.rb for LLM responses:

1. **Define typed structs** for data and action context
2. **Register schemas** when creating surfaces (schemas stay server-side)
3. **Client sends raw JSON** (like LLM responses)
4. **Server coerces automatically** using DSPy's TypeCoercion

This provides compile-time safety and IDE autocomplete without requiring schemas to travel over the wire.

#### Data Models

Surface data must be a `T::Struct`:

```ruby
class BookingData < T::Struct
  const :guests, Integer, default: 2
  const :date, T.nilable(String)
end

manager.create(
  surface_id: 'booking',
  request: 'Create a booking form',
  data: BookingData.new(guests: 4)
)

# For surfaces without data
manager.create(
  surface_id: 'welcome',
  request: 'Create a welcome message',
  data: A2UI::EmptyData.new
)
```

#### Action Context Types

Register context types when creating a surface. The server stores schemas internally and coerces incoming JSON automatically:

```ruby
# Define context types
class SubmitContext < T::Struct
  const :guests, Integer
  const :date, String
end

class CancelContext < T::Struct
  const :reason, T.nilable(String)
end

# Register when creating surface
manager.create(
  surface_id: 'booking',
  request: 'Create a booking form',
  data: BookingData.new,
  actions: {
    submit: SubmitContext,
    cancel: CancelContext
  }
)

# Client sends raw JSON, server coerces automatically
action = A2UI::UserAction.new(
  name: 'submit',
  surface_id: 'booking',
  source_id: 'btn',
  context: { 'guests' => '3', 'date' => '2025-01-15' }
)

result = manager.handle_action(action: action)
# Context coerced to SubmitContext.new(guests: 3, date: "2025-01-15")
```

#### Manual Coercion

For direct coercion (uses DSPy's TypeCoercion):

```ruby
context = A2UI::TypeCoercion.coerce(
  { 'guests' => '3', 'date' => '2025-01-15' },
  SubmitContext
)
# => SubmitContext.new(guests: 3, date: "2025-01-15")
```

### Components

Each component type maps to a ViewComponent:

| Struct | ViewComponent | Purpose |
|--------|---------------|---------|
| `TextComponent` | `A2UI::Components::Text` | Display text with semantic hints |
| `ButtonComponent` | `A2UI::Components::Button` | Trigger actions |
| `TextFieldComponent` | `A2UI::Components::TextField` | Text input with data binding |
| `CheckBoxComponent` | `A2UI::Components::CheckBox` | Boolean input |
| `SelectComponent` | `A2UI::Components::Select` | Dropdown select |
| `SliderComponent` | `A2UI::Components::Slider` | Range slider input |
| `RowComponent` | `A2UI::Components::Row` | Horizontal flex layout |
| `ColumnComponent` | `A2UI::Components::Column` | Vertical flex layout |
| `CardComponent` | `A2UI::Components::Card` | Container with elevation |
| `ListComponent` | `A2UI::Components::List` | List with data-driven children |
| `DividerComponent` | `A2UI::Components::Divider` | Visual separator |
| `TabsComponent` | `A2UI::Components::Tabs` | Tabbed content |
| `ModalComponent` | `A2UI::Components::Modal` | Modal dialogs |
| `ImageComponent` | `A2UI::Components::Image` | Images with fit modes |
| `IconComponent` | `A2UI::Components::Icon` | Icon display |

### Data Binding

Form inputs bind to the data model via JSON Pointer paths:

```ruby
# Component definition
A2UI::TextFieldComponent.new(
  id: 'guest-count',
  value: A2UI::PathReference.new(path: '/booking/guests'),
  input_type: A2UI::InputType::Number
)

# Renders with Stimulus binding
# <input data-controller="a2ui-binding"
#        data-a2ui-binding-path-value="/booking/guests" ...>
```

### Actions

Buttons dispatch actions with context from the data model:

```ruby
A2UI::ButtonComponent.new(
  id: 'submit',
  label: A2UI::LiteralValue.new(value: 'Book Now'),
  action: A2UI::Action.new(
    name: 'submit_booking',
    context: [
      A2UI::ContextBinding.new(key: 'booking', path: '/booking')
    ]
  )
)
```

## Stimulus Controllers

Three controllers handle client-side behavior:

- **`a2ui-data`** - Manages surface data model (JSON Pointer get/set)
- **`a2ui-binding`** - Two-way binding between inputs and data model
- **`a2ui-action`** - Dispatches user actions to server via fetch

## Routes

```ruby
namespace :a2ui do
  resources :surfaces, only: [:create, :show, :update, :destroy]
  resources :actions, only: [:create]
end
```

## Testing

```bash
bundle exec rspec spec/a2ui/types_spec.rb  # Unit tests (no API)
bundle exec rspec spec/a2ui/               # All tests (needs API key + VCR)
```

Integration tests use VCR to record LLM responses:

```ruby
RSpec.describe A2UI::GenerateUI, :vcr do
  it 'generates a booking form' do
    generator = A2UI::UIGenerator.new
    result = generator.call(
      request: 'Create a booking form',
      surface_id: 'booking'
    )

    expect(result.components).not_to be_empty
  end
end
```

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Type check (optional)
bundle exec srb tc
```

## JavaScript Package

For standalone use without Rails, see the `@a2ui/core` package:

```bash
npm install @a2ui/core
```

```typescript
import { renderSurface, type Surface } from '@a2ui/core';

const surface: Surface = {
  id: 'my-surface',
  root_id: 'card-1',
  components: { /* ... */ },
  data: {}
};

document.getElementById('app').innerHTML = renderSurface(surface);
```

See [packages/a2ui-js/README.md](packages/a2ui-js/README.md) for full documentation.

## Completed Features

- ✅ **15 Component Types** — Text, Button, TextField, CheckBox, Select, Slider, Row, Column, Card, List, Divider, Tabs, Modal, Image, Icon
- ✅ **Type-Safe Data** — Typed `T::Struct` for data and action context with DSPy TypeCoercion
- ✅ **Data-driven Children** — Repeat templates from arrays with `DataDrivenChildren`
- ✅ **Evidence Spans** — Track LLM reasoning for health predictions and UI decisions
- ✅ **Signal Modeling** — Detect significant changes in Garmin data and user activity
- ✅ **Rails Engine** — Mountable engine with configuration
- ✅ **Generators** — `a2_u_i:install` and `a2_u_i:surface`
- ✅ **JavaScript Package** — Standalone renderer for browser use

## Roadmap

- [ ] Optimizers for prompt tuning (MIPROv2 for signature optimization)
- [ ] Interactive A2UI playground demo app
- [ ] Publish to RubyGems and npm

## License

MIT

## See Also

- [Google A2UI](https://github.com/google/A2UI) - Original specification
- [DSPy.rb](https://github.com/vicentereig/dspy.rb) - Ruby DSPy framework
- [Hotwired Turbo](https://github.com/hotwired/turbo) - Turbo Streams/Frames
