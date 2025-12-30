# A2UI to Rails+Turbo Mapping

## Core Philosophy Alignment

Both A2UI and Turbo share a fundamental insight: **the server should be the source of truth for UI state**, and clients should receive declarative updates rather than imperative code.

| A2UI | Turbo |
|------|-------|
| JSON adjacency list | HTML fragments |
| `surfaceUpdate` | `<turbo-stream>` |
| `dataModelUpdate` | Stimulus values / form fields |
| `beginRendering` | Initial render / `<turbo-frame src="">` |
| `deleteSurface` | `<turbo-stream action="remove">` |
| Component catalog | ViewComponent library |
| Signal reactivity | Stimulus + Turbo events |

---

## Message Type Mappings

### 1. `beginRendering` → Initial Page Render / Turbo Frame

**A2UI:**
```json
{"beginRendering": {"surfaceId": "booking", "root": "layout", "catalogId": "standard/0.8"}}
```

**Rails+Turbo:**
```erb
<%# Controller renders initial frame %>
<turbo-frame id="booking" data-a2ui-surface="booking">
  <%= render A2ui::SurfaceComponent.new(surface_id: "booking", root_id: "layout") %>
</turbo-frame>
```

### 2. `surfaceUpdate` → Turbo Streams

**A2UI:**
```json
{
  "surfaceUpdate": {
    "surfaceId": "booking",
    "components": [
      {"id": "header", "component": {"Text": {"text": {"literalString": "Confirm"}, "usageHint": "h1"}}},
      {"id": "form", "component": {"Column": {"children": {"explicitList": ["guests", "date"]}}}}
    ]
  }
}
```

**Rails+Turbo:**
```erb
<turbo-stream action="update" target="booking">
  <template>
    <h1 id="header">Confirm</h1>
    <div id="form" class="flex flex-col">
      <%= render A2ui::TextFieldComponent.new(id: "guests", ...) %>
      <%= render A2ui::TextFieldComponent.new(id: "date", ...) %>
    </div>
  </template>
</turbo-stream>
```

### 3. `dataModelUpdate` → Stimulus Values + Hidden Fields

**A2UI:**
```json
{
  "dataModelUpdate": {
    "surfaceId": "booking",
    "path": "/reservation",
    "contents": [
      {"key": "guests", "valueString": "2"},
      {"key": "datetime", "valueString": "2025-12-16T19:00:00Z"}
    ]
  }
}
```

**Rails+Turbo:**
```erb
<turbo-stream action="update" target="booking-data">
  <template>
    <div id="booking-data"
         data-controller="a2ui-data"
         data-a2ui-data-model-value='{"reservation":{"guests":"2","datetime":"2025-12-16T19:00:00Z"}}'>
    </div>
  </template>
</turbo-stream>
```

### 4. `deleteSurface` → Turbo Stream Remove

**A2UI:**
```json
{"deleteSurface": {"surfaceId": "booking"}}
```

**Rails+Turbo:**
```erb
<turbo-stream action="remove" target="booking"></turbo-stream>
```

### 5. `userAction` → Turbo Form / Stimulus Action

**A2UI (client → server):**
```json
{
  "userAction": {
    "name": "confirmBooking",
    "surfaceId": "booking",
    "sourceComponentId": "confirm-btn",
    "context": {"guests": "3", "datetime": "2025-12-16T19:00:00Z"},
    "timestamp": "2025-12-30T10:00:00Z"
  }
}
```

**Rails+Turbo:**
```javascript
// Stimulus controller dispatches action
fetch('/a2ui/actions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'text/vnd.turbo-stream.html'
  },
  body: JSON.stringify({
    action: 'confirmBooking',
    surface_id: 'booking',
    source_component_id: 'confirm-btn',
    context: { guests: '3', datetime: '2025-12-16T19:00:00Z' }
  })
}).then(r => r.text()).then(html => Turbo.renderStreamMessage(html))
```

---

## Component Mapping

| A2UI Component | Rails ViewComponent | Turbo/Stimulus |
|----------------|---------------------|----------------|
| `Text` | `A2ui::TextComponent` | Static HTML |
| `Button` | `A2ui::ButtonComponent` | `data-controller="a2ui-action"` |
| `TextField` | `A2ui::TextFieldComponent` | `data-controller="a2ui-binding"` |
| `CheckBox` | `A2ui::CheckBoxComponent` | `data-controller="a2ui-binding"` |
| `Row` | `A2ui::RowComponent` | Flexbox container |
| `Column` | `A2ui::ColumnComponent` | Flexbox container |
| `Card` | `A2ui::CardComponent` | CSS card styles |
| `List` | `A2ui::ListComponent` | Scrollable container |
| `Tabs` | `A2ui::TabsComponent` | Stimulus tabs controller |
| `Modal` | `A2ui::ModalComponent` | Stimulus modal controller |

---

## DSPy.rb Signatures

The signatures in `lib/a2ui/signatures.rb` define the LLM interface:

### `GenerateUI`
Converts natural language → component adjacency list + data model.

```ruby
result = ui_generator.call(
  user_request: "Create a booking form with guest count and date picker",
  surface_id: "booking"
)
# Returns: root_id, components[], data_model[], reasoning
```

### `UpdateUI`
Generates incremental Turbo Stream operations.

```ruby
result = ui_updater.call(
  update_request: "Add a phone number field after the email",
  surface_id: "booking",
  existing_components: current_components
)
# Returns: streams[], new_components[], data_updates[]
```

### `HandleUserAction`
Processes user actions with business context.

```ruby
result = action_handler.call(
  action: user_action_input,
  business_context: "Max 10 guests per reservation"
)
# Returns: response_type, streams[], new_components[], message
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Rails Server                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │
│   │ Controllers  │────▶│ DSPy Modules │────▶│ ViewComponents│   │
│   │              │     │              │     │              │   │
│   │ - surfaces   │     │ - UIGenerator│     │ - Text       │   │
│   │ - actions    │     │ - UIUpdater  │     │ - Button     │   │
│   │              │     │ - ActionHndlr│     │ - TextField  │   │
│   └──────────────┘     └──────────────┘     │ - Row/Column │   │
│                                              │ - Card       │   │
│                                              └──────────────┘   │
│                               │                                  │
│                               ▼                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              TurboStreamRenderer                         │   │
│   │         (Converts components → Turbo Stream HTML)        │   │
│   └─────────────────────────────────────────────────────────┘   │
│                               │                                  │
└───────────────────────────────┼──────────────────────────────────┘
                                │
                    HTTP / WebSocket / SSE
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                         Browser                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│   │ Turbo Drive │  │ Turbo Frames│  │ Turbo Streams           │  │
│   │             │  │             │  │ (append/replace/remove) │  │
│   └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                                                                   │
│   ┌─────────────────────────────────────────────────────────────┐ │
│   │                 Stimulus Controllers                         │ │
│   │                                                              │ │
│   │  a2ui-data     - Surface data model management               │ │
│   │  a2ui-binding  - Two-way data binding for inputs             │ │
│   │  a2ui-action   - User action dispatch to server              │ │
│   │  a2ui-surface  - Surface lifecycle management                │ │
│   │                                                              │ │
│   └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Streaming Updates

### A2UI JSONL Streaming
```jsonl
{"surfaceUpdate":{"surfaceId":"chat","components":[...]}}
{"dataModelUpdate":{"surfaceId":"chat","path":"/messages","contents":[...]}}
```

### Rails ActionCable + Turbo Streams
```ruby
# Broadcasting from anywhere
Turbo::StreamsChannel.broadcast_update_to(
  "a2ui:#{surface_id}",
  target: component_id,
  partial: "a2ui/components/text",
  locals: { component: text_component }
)
```

```erb
<%# In view %>
<%= turbo_stream_from "a2ui:#{@surface_id}" %>
```

---

## Implementation Roadmap

### Phase 1: Core Infrastructure
- [ ] Rails app with Turbo + Stimulus
- [ ] DSPy.rb configuration
- [ ] Base Sorbet types (`lib/a2ui/signatures.rb`)
- [ ] Base DSPy modules (`lib/a2ui/modules.rb`)

### Phase 2: Component Library
- [ ] ViewComponent base class with A2UI props
- [ ] Text, Button, TextField components
- [ ] Row, Column, Card layout components
- [ ] TurboStreamRenderer

### Phase 3: Stimulus Controllers
- [ ] `a2ui-data` - Data model management
- [ ] `a2ui-binding` - Input binding
- [ ] `a2ui-action` - Action dispatch

### Phase 4: Rails Integration
- [ ] `A2ui::SurfacesController`
- [ ] `A2ui::ActionsController`
- [ ] ActionCable channel for streaming

### Phase 5: Sample App
- [ ] Booking form demo
- [ ] Chat interface demo
- [ ] Dashboard with multiple surfaces
