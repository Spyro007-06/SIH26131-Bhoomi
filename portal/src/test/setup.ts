import '@testing-library/jest-dom';
import { afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';

// Automatically cleanup after each test
afterEach(() => {
  cleanup();
});

// Patch Node 22 Undici Request / JSDOM AbortSignal incompatibility
const NativeRequest = globalThis.Request;
if (NativeRequest) {
  class PatchedRequest extends NativeRequest {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    constructor(input: any, init?: any) {
      if (init && 'signal' in init) {
        // Strip JSDOM signal so Undici NativeRequest doesn't reject WebIDL instance check
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { signal, ...restInit } = init;
        super(input, restInit);
        return;
      }
      super(input, init);
    }
  }
  globalThis.Request = PatchedRequest as unknown as typeof Request;
  window.Request = PatchedRequest as unknown as typeof Request;
}

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};
