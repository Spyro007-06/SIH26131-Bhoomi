import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bhoomi: {
          primary: {
            DEFAULT: 'var(--bhoomi-primary, #2E7D32)',
            dark: 'var(--bhoomi-primary-dark, #1B5E20)',
            light: 'var(--bhoomi-primary-light, #EAF4EA)',
            soft: 'var(--bhoomi-primary-soft, #F3F8F3)',
          },
          green: {
            50: 'var(--bhoomi-green-50, #F3F8F3)',
            100: 'var(--bhoomi-green-100, #EAF4EA)',
            500: 'var(--bhoomi-green-500, #4CAF50)',
            600: 'var(--bhoomi-green-600, #2E7D32)',
            700: 'var(--bhoomi-green-700, #2E7D32)',
            800: 'var(--bhoomi-green-800, #1B5E20)',
            900: 'var(--bhoomi-green-900, #1B5E20)',
          },
          canvas: 'var(--bhoomi-canvas, #F8FAFC)',
          surface: {
            DEFAULT: 'var(--bhoomi-surface, #FFFFFF)',
            soft: 'var(--bhoomi-surface-soft, #F1F5F9)',
            hover: 'var(--bhoomi-surface-hover, #F8FAFC)',
          },
          white: 'var(--bhoomi-white, #FFFFFF)',
          background: 'var(--bhoomi-background, #F8FAFC)',
          'surface-soft': 'var(--bhoomi-surface-soft, #F1F5F9)',
          border: {
            DEFAULT: 'var(--bhoomi-border, #E2E8F0)',
            strong: 'var(--bhoomi-border-strong, #CBD5E1)',
          },
          'border-strong': 'var(--bhoomi-border-strong, #CBD5E1)',
          text: {
            DEFAULT: 'var(--bhoomi-text-primary, #0F172A)',
            primary: 'var(--bhoomi-text-primary, #0F172A)',
            secondary: 'var(--bhoomi-text-secondary, #475569)',
            muted: 'var(--bhoomi-text-muted, #64748B)',
            disabled: 'var(--bhoomi-text-disabled, #94A3B8)',
          },
          'text-secondary': 'var(--bhoomi-text-secondary, #475569)',
          success: {
            DEFAULT: 'var(--bhoomi-success, #16A34A)',
            soft: 'var(--bhoomi-success-soft, #ECFDF3)',
          },
          warning: {
            DEFAULT: 'var(--bhoomi-warning, #F59E0B)',
            soft: 'var(--bhoomi-warning-soft, #FFF7DB)',
          },
          danger: {
            DEFAULT: 'var(--bhoomi-danger, #DC2626)',
            soft: 'var(--bhoomi-danger-soft, #FEF2F2)',
          },
          info: {
            DEFAULT: 'var(--bhoomi-info, #2563EB)',
            soft: 'var(--bhoomi-info-soft, #EFF6FF)',
          },
          escalation: {
            DEFAULT: 'var(--bhoomi-escalation, #9333EA)',
            soft: 'var(--bhoomi-escalation-soft, #FAF5FF)',
          },
          cream: 'var(--bhoomi-cream, #FAF7EF)',
        },
      },
      borderRadius: {
        card: '16px',
        '2xl': '16px',
      },
      boxShadow: {
        subtle: 'var(--shadow-subtle)',
        card: 'var(--shadow-card)',
        xs: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config;
