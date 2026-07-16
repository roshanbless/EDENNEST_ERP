/**
 * Pure business logic for the Production module.
 * No database or framework imports here — see docs/erd.md §12.2.
 */

export interface ProductionLogInput {
  birdsCount: number;
  eggsProduced: number;
  brokenEggs: number;
}

/**
 * Production percentage = eggs produced ÷ bird count × 100.
 * This is the canonical formula referenced across the dashboard,
 * analytics rollups, and the module docs — defined once, here.
 */
export function calculateProductionPercentage(input: ProductionLogInput): number {
  if (input.birdsCount <= 0) return 0;
  return Number(((input.eggsProduced / input.birdsCount) * 100).toFixed(1));
}

/**
 * Quality grade assignment based on broken-egg ratio.
 * Threshold matches the Quality Control module's rejection-rate alerting.
 */
export function assignQualityGrade(input: ProductionLogInput): "A" | "B" | "C" {
  if (input.eggsProduced <= 0) return "C";
  const brokenRatio = input.brokenEggs / input.eggsProduced;
  if (brokenRatio > 0.05) return "C";
  if (brokenRatio > 0.025) return "B";
  return "A";
}
