import type { AssessmentSkill } from '@/types'

export function buildSkillsPayload(
  original: AssessmentSkill[],
  current: AssessmentSkill[],
): Partial<AssessmentSkill>[] {
  const keptIds = new Set(current.filter(s => s.id != null).map(s => s.id))
  const removed = original
    .filter(s => s.id != null && !keptIds.has(s.id))
    .map(s => ({ id: s.id, _destroy: true }))
  const kept = current.map((s, i) => ({ ...s, display_order: i }))
  return []
}