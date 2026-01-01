/**
 * A2UI JavaScript Package
 * Standalone rendering of A2UI components
 */

// Export types
export * from './types';

// Export renderer
export { renderComponent, renderSurface, resolveValue, resolveChildren } from './renderer';
export type { RenderContext } from './renderer';

// Version
export const VERSION = '0.1.0';
