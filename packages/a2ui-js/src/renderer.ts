/**
 * A2UI Component Renderer
 * Renders A2UI components to HTML
 */

import type {
  Component,
  Value,
  Children,
  Surface,
  TextComponent,
  ButtonComponent,
  TextFieldComponent,
  CheckBoxComponent,
  RowComponent,
  ColumnComponent,
  CardComponent,
  ListComponent,
  DividerComponent,
  TabsComponent,
  ModalComponent,
} from './types';

export interface RenderContext {
  surface: Surface;
  data: Record<string, unknown>;
  prefix?: string;
}

/**
 * Resolve a Value to a string
 */
export function resolveValue(value: Value, data: Record<string, unknown>): string {
  if (value._type === 'LiteralValue') {
    return value.value;
  }

  // PathReference - resolve from data
  const path = value.path.replace(/^\//, '').split('/');
  let current: unknown = data;

  for (const segment of path) {
    if (current && typeof current === 'object' && segment in current) {
      current = (current as Record<string, unknown>)[segment];
    } else {
      return '';
    }
  }

  return String(current ?? '');
}

/**
 * Resolve children IDs
 */
export function resolveChildren(children: Children, data: Record<string, unknown>): string[] {
  if (children._type === 'ExplicitChildren') {
    return children.ids;
  }

  // DataDrivenChildren - resolve array from path
  const path = children.path.replace(/^\//, '').split('/');
  let current: unknown = data;

  for (const segment of path) {
    if (current && typeof current === 'object' && segment in current) {
      current = (current as Record<string, unknown>)[segment];
    } else {
      return [];
    }
  }

  if (!Array.isArray(current)) {
    return [];
  }

  // Return template ID for each item
  return current.map((_, index) => `${children.template_id}_${index}`);
}

/**
 * CSS class helpers
 */
function cx(...classes: (string | undefined | false)[]): string {
  return classes.filter(Boolean).join(' ');
}

/**
 * Component renderers
 */
const renderers: Record<string, (component: Component, ctx: RenderContext) => string> = {
  TextComponent(component: Component, ctx: RenderContext): string {
    const c = component as TextComponent;
    const content = resolveValue(c.content, ctx.data);
    const hint = c.usage_hint || 'body';
    const prefix = ctx.prefix || 'a2ui';

    const tagMap: Record<string, string> = {
      h1: 'h1',
      h2: 'h2',
      h3: 'h3',
      body: 'p',
      caption: 'span',
      label: 'label',
    };

    const tag = tagMap[hint] || 'span';
    return `<${tag} id="${c.id}" class="${prefix}-text ${prefix}-text--${hint}">${escapeHtml(content)}</${tag}>`;
  },

  ButtonComponent(component: Component, ctx: RenderContext): string {
    const c = component as ButtonComponent;
    const label = resolveValue(c.label, ctx.data);
    const variant = c.variant || 'primary';
    const prefix = ctx.prefix || 'a2ui';
    const disabled = c.disabled ? 'disabled' : '';

    const actionData = c.action
      ? `data-action="${c.action.name}" data-context='${JSON.stringify(c.action.context)}'`
      : '';

    return `<button id="${c.id}" class="${prefix}-button ${prefix}-button--${variant}" ${actionData} ${disabled}>${escapeHtml(label)}</button>`;
  },

  TextFieldComponent(component: Component, ctx: RenderContext): string {
    const c = component as TextFieldComponent;
    const value = resolveValue(c.value, ctx.data);
    const prefix = ctx.prefix || 'a2ui';
    const inputType = c.input_type || 'text';
    const required = c.is_required ? 'required' : '';
    const disabled = c.is_disabled ? 'disabled' : '';

    let html = `<div id="${c.id}" class="${prefix}-text-field">`;
    if (c.label) {
      html += `<label class="${prefix}-text-field__label">${escapeHtml(c.label)}</label>`;
    }
    html += `<input type="${inputType}" class="${prefix}-text-field__input" value="${escapeHtml(value)}" placeholder="${escapeHtml(c.placeholder || '')}" ${required} ${disabled} />`;
    html += '</div>';

    return html;
  },

  CheckBoxComponent(component: Component, ctx: RenderContext): string {
    const c = component as CheckBoxComponent;
    const value = resolveValue(c.value, ctx.data);
    const checked = value === 'true' || value === '1' ? 'checked' : '';
    const prefix = ctx.prefix || 'a2ui';

    let html = `<div id="${c.id}" class="${prefix}-checkbox">`;
    html += `<input type="checkbox" class="${prefix}-checkbox__input" ${checked} />`;
    if (c.label) {
      html += `<label class="${prefix}-checkbox__label">${escapeHtml(c.label)}</label>`;
    }
    html += '</div>';

    return html;
  },

  RowComponent(component: Component, ctx: RenderContext): string {
    const c = component as RowComponent;
    const prefix = ctx.prefix || 'a2ui';
    const childIds = resolveChildren(c.children, ctx.data);
    const gap = c.gap ? `gap: ${c.gap}px;` : '';
    const distribution = c.distribution ? `${prefix}-distribute--${c.distribution.replace('_', '-')}` : '';
    const alignment = c.alignment ? `${prefix}-align--${c.alignment}` : '';

    const childrenHtml = childIds
      .map(id => {
        const child = ctx.surface.components[id];
        return child ? renderComponent(child, ctx) : '';
      })
      .join('');

    return `<div id="${c.id}" class="${cx(prefix + '-row', distribution, alignment)}" style="${gap}">${childrenHtml}</div>`;
  },

  ColumnComponent(component: Component, ctx: RenderContext): string {
    const c = component as ColumnComponent;
    const prefix = ctx.prefix || 'a2ui';
    const childIds = resolveChildren(c.children, ctx.data);
    const gap = c.gap ? `gap: ${c.gap}px;` : '';
    const distribution = c.distribution ? `${prefix}-distribute--${c.distribution.replace('_', '-')}` : '';
    const alignment = c.alignment ? `${prefix}-align--${c.alignment}` : '';

    const childrenHtml = childIds
      .map(id => {
        const child = ctx.surface.components[id];
        return child ? renderComponent(child, ctx) : '';
      })
      .join('');

    return `<div id="${c.id}" class="${cx(prefix + '-column', distribution, alignment)}" style="${gap}">${childrenHtml}</div>`;
  },

  CardComponent(component: Component, ctx: RenderContext): string {
    const c = component as CardComponent;
    const prefix = ctx.prefix || 'a2ui';
    const child = ctx.surface.components[c.child_id];
    const childHtml = child ? renderComponent(child, ctx) : '';
    const elevation = c.elevation ? `box-shadow: 0 ${c.elevation}px ${c.elevation * 2}px rgba(0,0,0,0.1);` : '';

    return `<div id="${c.id}" class="${prefix}-card" style="${elevation}">${childHtml}</div>`;
  },

  ListComponent(component: Component, ctx: RenderContext): string {
    const c = component as ListComponent;
    const prefix = ctx.prefix || 'a2ui';
    const childIds = resolveChildren(c.children, ctx.data);
    const orientation = c.orientation || 'vertical';
    const gap = c.gap ? `gap: ${c.gap}px;` : '';

    const childrenHtml = childIds
      .map(id => {
        const child = ctx.surface.components[id];
        return child ? `<li>${renderComponent(child, ctx)}</li>` : '';
      })
      .join('');

    return `<ul id="${c.id}" class="${prefix}-list ${prefix}-list--${orientation}" style="${gap}">${childrenHtml}</ul>`;
  },

  DividerComponent(component: Component, ctx: RenderContext): string {
    const c = component as DividerComponent;
    const prefix = ctx.prefix || 'a2ui';
    const orientation = c.orientation || 'horizontal';

    return `<hr id="${c.id}" class="${prefix}-divider ${prefix}-divider--${orientation}" />`;
  },

  TabsComponent(component: Component, ctx: RenderContext): string {
    const c = component as TabsComponent;
    const prefix = ctx.prefix || 'a2ui';
    const activeIndex = c.active_index ?? 0;

    const tabsHtml = c.tabs
      .map((tab, index) => {
        const isActive = index === activeIndex ? 'active' : '';
        return `<button class="${prefix}-tab ${isActive}" data-index="${index}">${escapeHtml(tab.label)}</button>`;
      })
      .join('');

    const activeTab = c.tabs[activeIndex];
    const activeChild = activeTab ? ctx.surface.components[activeTab.child_id] : null;
    const contentHtml = activeChild ? renderComponent(activeChild, ctx) : '';

    return `
      <div id="${c.id}" class="${prefix}-tabs">
        <div class="${prefix}-tabs__header">${tabsHtml}</div>
        <div class="${prefix}-tabs__content">${contentHtml}</div>
      </div>
    `;
  },

  ModalComponent(component: Component, ctx: RenderContext): string {
    const c = component as ModalComponent;
    const prefix = ctx.prefix || 'a2ui';
    const isOpen = c.is_open ? 'open' : '';
    const size = c.size || 'medium';
    const child = ctx.surface.components[c.child_id];
    const contentHtml = child ? renderComponent(child, ctx) : '';

    return `
      <div id="${c.id}" class="${prefix}-modal ${prefix}-modal--${size} ${isOpen}">
        <div class="${prefix}-modal__backdrop"></div>
        <div class="${prefix}-modal__container">
          ${c.title ? `<div class="${prefix}-modal__header"><h2>${escapeHtml(c.title)}</h2>${c.dismissible !== false ? `<button class="${prefix}-modal__close">&times;</button>` : ''}</div>` : ''}
          <div class="${prefix}-modal__content">${contentHtml}</div>
        </div>
      </div>
    `;
  },
};

/**
 * Escape HTML special characters
 */
function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}

/**
 * Render a single component
 */
export function renderComponent(component: Component, ctx: RenderContext): string {
  const renderer = renderers[component._type];
  if (!renderer) {
    return `<div id="${component.id}" class="a2ui-unsupported">Unsupported: ${component._type}</div>`;
  }
  return renderer(component, ctx);
}

/**
 * Render a complete surface
 */
export function renderSurface(surface: Surface, options?: { prefix?: string }): string {
  const ctx: RenderContext = {
    surface,
    data: surface.data,
    prefix: options?.prefix || 'a2ui',
  };

  const root = surface.components[surface.root_id];
  if (!root) {
    return `<div id="${surface.id}" class="a2ui-surface a2ui-empty">No root component</div>`;
  }

  return `<div id="${surface.id}" class="a2ui-surface">${renderComponent(root, ctx)}</div>`;
}
