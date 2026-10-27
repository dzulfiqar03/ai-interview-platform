import { describe, it, expect } from 'vitest'
import { buildSkillsPayload } from './buildSkillsPayload'

const s = (id: number | undefined) => ({ id, skill_label: `s${id}` }) as any

describe('buildSkillsPayload', () => {
  it('marks removed saved skills with _destroy', () => {
    const out = buildSkillsPayload([s(4), s(5)], [s(5)])
    expect(out).toContainEqual({ id: 4, _destroy: true })
  })
  it('does not send _destroy for kept skills', () => {
    const out = buildSkillsPayload([s(4), s(5)], [s(5)])
    expect(out.find(x => x.id === 5)?._destroy).toBeUndefined()
  })
  it('ignores new unsaved skills that were removed', () => {
    expect(buildSkillsPayload([s(5)], [s(5)]).some(x => x._destroy)).toBe(false)
  })
})