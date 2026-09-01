import { ReactNode } from 'react';

export type ComponentSize = 'sm' | 'md' | 'lg';

export type ComponentVariant = 'primary' | 'secondary' | 'outline' | 'danger' | 'ghost';

export interface BaseComponentProps {
  className?: string;
  children?: ReactNode;
}

export interface NavItem {
  label: string;
  path: string;
  icon?: ReactNode;
  badge?: string | number;
}
