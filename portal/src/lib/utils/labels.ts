import { Crop, ProblemSeverity, CaseStatus } from '@/types/enums';

export function formatTargetLabel(label: string): string {
  if (!label) return '';
  return label
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export function formatCropName(crop: Crop | string): string {
  if (!crop) return '';
  return crop.charAt(0).toUpperCase() + crop.slice(1);
}

export function getSeverityBadgeVariant(
  severity: ProblemSeverity | string
): 'danger' | 'warning' | 'primary' | 'secondary' {
  switch (severity) {
    case 'severe':
      return 'danger';
    case 'moderate':
      return 'warning';
    case 'early':
      return 'primary';
    default:
      return 'secondary';
  }
}

export function getStatusBadgeVariant(
  status: CaseStatus | string
): 'danger' | 'warning' | 'primary' | 'secondary' {
  switch (status) {
    case 'open':
      return 'warning';
    case 'assigned':
      return 'primary';
    case 'resolved':
      return 'secondary';
    default:
      return 'secondary';
  }
}
