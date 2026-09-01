/**
 * Presentation formatters for BHOOMI UI.
 * Note: These formatters ONLY transform strings for visual rendering.
 * Raw API values (snake_case target labels, UUIDs, ISO UTC timestamps) remain unmodified in state.
 */

export function formatTargetLabel(label: string | null | undefined): string {
  if (!label || label.trim().length === 0) {
    return 'Pending Assessment';
  }

  // E.g. "paddy_blast" -> "Paddy Blast"
  // E.g. "cotton_bacterial_blight" -> "Cotton Bacterial Blight"
  return label
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

export function formatDateTime(isoString: string | null | undefined): string {
  if (!isoString) return '—';
  try {
    const date = new Date(isoString);
    if (isNaN(date.getTime())) return isoString;
    return new Intl.DateTimeFormat('en-IN', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    }).format(date);
  } catch {
    return isoString;
  }
}

export function formatRelativeTime(isoString: string | null | undefined): string {
  if (!isoString) return '—';
  try {
    const date = new Date(isoString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    if (isNaN(diffMs)) return isoString;

    const diffMins = Math.floor(diffMs / (1000 * 60));
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays}d ago`;

    return formatDateTime(isoString);
  } catch {
    return isoString;
  }
}

export function formatShortId(id: string): string {
  if (!id) return '';
  if (id.length <= 8) return id;
  return `${id.slice(0, 8)}…`;
}
