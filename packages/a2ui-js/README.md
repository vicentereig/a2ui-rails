# @a2ui/core

JavaScript/TypeScript package for rendering A2UI components in the browser.

## Installation

```bash
npm install @a2ui/core
# or
yarn add @a2ui/core
```

## Usage

### Basic Rendering

```typescript
import { renderSurface, type Surface } from '@a2ui/core';

const surface: Surface = {
  id: 'my-surface',
  root_id: 'card-1',
  components: {
    'card-1': {
      _type: 'CardComponent',
      id: 'card-1',
      child_id: 'text-1',
    },
    'text-1': {
      _type: 'TextComponent',
      id: 'text-1',
      content: { _type: 'LiteralValue', value: 'Hello, A2UI!' },
      usage_hint: 'h1',
    },
  },
  data: {},
};

const html = renderSurface(surface);
document.getElementById('app').innerHTML = html;
```

### Data Binding

```typescript
import { renderSurface, type Surface } from '@a2ui/core';

const surface: Surface = {
  id: 'user-card',
  root_id: 'column-1',
  components: {
    'column-1': {
      _type: 'ColumnComponent',
      id: 'column-1',
      children: { _type: 'ExplicitChildren', ids: ['greeting', 'name'] },
      gap: 8,
    },
    greeting: {
      _type: 'TextComponent',
      id: 'greeting',
      content: { _type: 'LiteralValue', value: 'Welcome,' },
      usage_hint: 'caption',
    },
    name: {
      _type: 'TextComponent',
      id: 'name',
      content: { _type: 'PathReference', path: '/user/name' },
      usage_hint: 'h2',
    },
  },
  data: {
    user: {
      name: 'Alice',
    },
  },
};

const html = renderSurface(surface);
// Renders: Welcome, Alice
```

### Custom CSS Prefix

```typescript
const html = renderSurface(surface, { prefix: 'my-app' });
// Uses classes like: my-app-text, my-app-button, etc.
```

## Component Types

- **TextComponent** - Text with usage hints (h1, h2, h3, body, caption, label)
- **ButtonComponent** - Buttons with actions
- **TextFieldComponent** - Text input fields
- **CheckBoxComponent** - Checkbox inputs
- **SelectComponent** - Dropdown selects
- **SliderComponent** - Range sliders
- **ImageComponent** - Images with fit modes
- **IconComponent** - Icons
- **RowComponent** - Horizontal layout
- **ColumnComponent** - Vertical layout
- **CardComponent** - Card container with elevation
- **ListComponent** - List container
- **DividerComponent** - Horizontal/vertical divider
- **TabsComponent** - Tabbed content
- **ModalComponent** - Modal dialogs

## Value Types

### LiteralValue
Static string value:
```typescript
{ _type: 'LiteralValue', value: 'Hello' }
```

### PathReference
Dynamic value from data:
```typescript
{ _type: 'PathReference', path: '/user/name' }
```

## Children Types

### ExplicitChildren
Explicit list of component IDs:
```typescript
{ _type: 'ExplicitChildren', ids: ['child-1', 'child-2'] }
```

### DataDrivenChildren
Repeat a template for each item in an array:
```typescript
{ _type: 'DataDrivenChildren', path: '/items', template_id: 'item-template' }
```

## CSS Classes

The renderer outputs semantic CSS classes that you can style:

```css
.a2ui-text--h1 { font-size: 2rem; }
.a2ui-button--primary { background: blue; }
.a2ui-row { display: flex; flex-direction: row; }
.a2ui-column { display: flex; flex-direction: column; }
```

## License

MIT
