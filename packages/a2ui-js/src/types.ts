/**
 * A2UI Core Types
 * TypeScript definitions for A2UI components and data structures
 */

// Enums
export type TextUsageHint = 'h1' | 'h2' | 'h3' | 'body' | 'caption' | 'label';
export type InputType = 'text' | 'email' | 'password' | 'number' | 'tel' | 'url';
export type Distribution = 'start' | 'center' | 'end' | 'space_between' | 'space_around' | 'space_evenly';
export type Alignment = 'start' | 'center' | 'end' | 'stretch';
export type Orientation = 'horizontal' | 'vertical';
export type ImageFit = 'contain' | 'cover' | 'fill' | 'none' | 'scale_down';
export type ModalSize = 'small' | 'medium' | 'large' | 'fullscreen';
export type StreamAction = 'append' | 'prepend' | 'replace' | 'update' | 'remove' | 'before' | 'after';

// Value types
export interface LiteralValue {
  _type: 'LiteralValue';
  value: string;
}

export interface PathReference {
  _type: 'PathReference';
  path: string;
}

export type Value = LiteralValue | PathReference;

// Children types
export interface ExplicitChildren {
  _type: 'ExplicitChildren';
  ids: string[];
}

export interface DataDrivenChildren {
  _type: 'DataDrivenChildren';
  path: string;
  template_id: string;
}

export type Children = ExplicitChildren | DataDrivenChildren;

// Action types
export interface ContextBinding {
  key: string;
  path: string;
}

export interface Action {
  name: string;
  context: ContextBinding[];
}

// Component types
export interface BaseComponent {
  id: string;
}

export interface TextComponent extends BaseComponent {
  _type: 'TextComponent';
  content: Value;
  usage_hint?: TextUsageHint;
}

export interface ButtonComponent extends BaseComponent {
  _type: 'ButtonComponent';
  label: Value;
  action?: Action;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
}

export interface TextFieldComponent extends BaseComponent {
  _type: 'TextFieldComponent';
  value: Value;
  label?: string;
  placeholder?: string;
  input_type?: InputType;
  is_required?: boolean;
  is_disabled?: boolean;
}

export interface CheckBoxComponent extends BaseComponent {
  _type: 'CheckBoxComponent';
  value: Value;
  label?: string;
}

export interface SelectComponent extends BaseComponent {
  _type: 'SelectComponent';
  value: Value;
  options_path: string;
  label?: string;
  placeholder?: string;
}

export interface SliderComponent extends BaseComponent {
  _type: 'SliderComponent';
  value: Value;
  min: number;
  max: number;
  step?: number;
  label?: string;
}

export interface ImageComponent extends BaseComponent {
  _type: 'ImageComponent';
  src: Value;
  alt?: string;
  fit?: ImageFit;
}

export interface IconComponent extends BaseComponent {
  _type: 'IconComponent';
  name: Value;
  size?: number;
}

export interface RowComponent extends BaseComponent {
  _type: 'RowComponent';
  children: Children;
  distribution?: Distribution;
  alignment?: Alignment;
  gap?: number;
}

export interface ColumnComponent extends BaseComponent {
  _type: 'ColumnComponent';
  children: Children;
  distribution?: Distribution;
  alignment?: Alignment;
  gap?: number;
}

export interface CardComponent extends BaseComponent {
  _type: 'CardComponent';
  child_id: string;
  elevation?: number;
}

export interface ListComponent extends BaseComponent {
  _type: 'ListComponent';
  children: Children;
  orientation?: Orientation;
  gap?: number;
}

export interface DividerComponent extends BaseComponent {
  _type: 'DividerComponent';
  orientation?: Orientation;
}

export interface TabItem {
  label: string;
  child_id: string;
}

export interface TabsComponent extends BaseComponent {
  _type: 'TabsComponent';
  tabs: TabItem[];
  active_index?: number;
}

export interface ModalComponent extends BaseComponent {
  _type: 'ModalComponent';
  child_id: string;
  title?: string;
  is_open?: boolean;
  size?: ModalSize;
  dismissible?: boolean;
}

export type Component =
  | TextComponent
  | ButtonComponent
  | TextFieldComponent
  | CheckBoxComponent
  | SelectComponent
  | SliderComponent
  | ImageComponent
  | IconComponent
  | RowComponent
  | ColumnComponent
  | CardComponent
  | ListComponent
  | DividerComponent
  | TabsComponent
  | ModalComponent;

// Surface types
export interface Surface {
  id: string;
  root_id: string;
  components: Record<string, Component>;
  data: Record<string, unknown>;
}

// Stream operation types
export interface StreamOp {
  action: StreamAction;
  target: string;
  component_ids: string[];
}

// Data update types
export interface DataUpdate {
  path: string;
  value: unknown;
}
