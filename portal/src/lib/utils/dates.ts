import { format, formatDistanceToNow, parseISO, isValid } from 'date-fns';

export function formatDate(dateString: string | null | undefined, formatPattern = 'dd MMM yyyy'): string {
  if (!dateString) return '—';
  try {
    const parsed = parseISO(dateString);
    return isValid(parsed) ? format(parsed, formatPattern) : dateString;
  } catch {
    return dateString;
  }
}

export function formatDateTime(
  dateString: string | null | undefined,
  formatPattern = 'dd MMM yyyy, HH:mm'
): string {
  if (!dateString) return '—';
  try {
    const parsed = parseISO(dateString);
    return isValid(parsed) ? format(parsed, formatPattern) : dateString;
  } catch {
    return dateString;
  }
}

export function formatRelativeTime(dateString: string | null | undefined): string {
  if (!dateString) return '—';
  try {
    const parsed = parseISO(dateString);
    return isValid(parsed) ? formatDistanceToNow(parsed, { addSuffix: true }) : dateString;
  } catch {
    return dateString;
  }
}
