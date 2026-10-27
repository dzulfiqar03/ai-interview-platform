type WithId = { id?: number | null }

export function buildSkillsPayload<T extends WithId>(original: T[], current: T[], withOrder = true) {
  const keptIds = new Set(current.filter(s => s.id != null).map(s => s.id))
  const removed = original
    .filter(s => s.id != null && !keptIds.has(s.id))
    .map(s => ({ id: s.id, _destroy: true }))
  const kept = current.map((s, i) => (withOrder ? { ...s, display_order: i } : s))
  return [...kept, ...removed]
}