import { describe, expect, it } from 'vitest'
import {
  FEATURE_FLAGS,
  defaultFeaturesByPlan,
  isFeatureFlag,
  resolveEnabledFeatures,
  templatesOfPlan,
} from './feature-flags'

describe('templatesOfPlan', () => {
  it('essential only offers aura and bosque', () => {
    expect(templatesOfPlan('essential')).toEqual(['aura', 'bosque'])
  })

  it('premium and enterprise offer all five real templates', () => {
    expect(templatesOfPlan('premium')).toEqual(['aura', 'bosque', 'elite', 'pulse', 'horizon'])
    expect(templatesOfPlan('enterprise')).toEqual(['aura', 'bosque', 'elite', 'pulse', 'horizon'])
  })
})

describe('defaultFeaturesByPlan', () => {
  it('essential has no premium-exclusive flags by default', () => {
    expect(defaultFeaturesByPlan('essential')).toEqual([])
  })

  it('premium and enterprise default to every known flag', () => {
    expect(defaultFeaturesByPlan('premium')).toEqual([...FEATURE_FLAGS])
    expect(defaultFeaturesByPlan('enterprise')).toEqual([...FEATURE_FLAGS])
  })
})

describe('resolveEnabledFeatures', () => {
  it('essential with no courtesy extras has nothing enabled', () => {
    expect(resolveEnabledFeatures('essential')).toEqual([])
  })

  it('essential can get a single premium feature as a courtesy without changing plan', () => {
    expect(resolveEnabledFeatures('essential', ['interactive_map'])).toEqual(['interactive_map'])
  })

  it('ignores unknown/stale flag strings instead of throwing', () => {
    expect(resolveEnabledFeatures('essential', ['not_a_real_flag'])).toEqual([])
  })

  it('never duplicates a flag that is both a plan default and listed as an extra', () => {
    const result = resolveEnabledFeatures('premium', ['loyalty'])
    expect(result.filter((f) => f === 'loyalty')).toHaveLength(1)
  })

  it('premium has every flag enabled by default', () => {
    expect(resolveEnabledFeatures('premium').sort()).toEqual([...FEATURE_FLAGS].sort())
  })
})

describe('isFeatureFlag', () => {
  it('accepts every catalog entry and rejects anything else', () => {
    for (const flag of FEATURE_FLAGS) expect(isFeatureFlag(flag)).toBe(true)
    expect(isFeatureFlag('basic_notifications')).toBe(false)
  })
})
