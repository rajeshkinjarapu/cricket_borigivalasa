String formatDate(DateTime? dt) {
  if (dt == null) return '—';
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}
String formatDateRange(DateTime? s, DateTime? e) {
  if (s == null && e == null) return 'Dates TBD';
  if (s != null && e == null) return 'From ${formatDate(s)}';
  if (s == null && e != null) return 'Until ${formatDate(e)}';
  return '${formatDate(s)} – ${formatDate(e)}';
}
