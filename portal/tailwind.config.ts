import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bhoomi: {
          green: {
            50: 'var(--bhoomi-green-50, #F1F8E9)',
            100: 'var(--bhoomi-green-100, #E8F5E9)',
            500: 'var(--bhoomi-green-500, #66BB6A)',
            600: 'var(--bhoomi-green-600, #2E7D32)',
            700: 'var(--bhoomi-green-700, #15803D)',
            800: 'var(--bhoomi-green-800, #166534)',
            900: 'var(--bhoomi-green-900, #14532D)',
          },
          white: 'var(--bhoomi-white, #FFFFFF)',
          background: 'var(--bhoomi-background, #FAFCF8)',
          'surface-soft': 'var(--bhoomi-surface-soft, #F5F7F2)',
          border: 'var(--bhoomi-border, #E5E7E3)',
          'border-strong': 'var(--bhoomi-border-strong, #D1D5D1)',
          text: 'var(--bhoomi-text, #17201A)',
          'text-secondary': 'var(--bhoomi-text-secondary, #374151)',
          success: 'var(--bhoomi-success, #2E7D32)',
          warning: 'var(--bhoomi-warning, #D97706)',
          danger: 'var(--bhoomi-danger, #C62828)',
          info: 'var(--bhoomi-info, #2563EB)',
          cream: 'var(--bhoomi-cream, #FAF7EF)',
        },
      },
      borderRadius: {
        card: '14px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config;
