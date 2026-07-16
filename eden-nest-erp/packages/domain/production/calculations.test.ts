import { describe, it, expect } from "vitest";
import { calculateProductionPercentage, assignQualityGrade } from "./calculations";

describe("calculateProductionPercentage", () => {
  it("returns 0 when bird count is zero", () => {
    expect(
      calculateProductionPercentage({ birdsCount: 0, eggsProduced: 100, brokenEggs: 0 })
    ).toBe(0);
  });

  it("computes eggs produced over bird count as a percentage", () => {
    expect(
      calculateProductionPercentage({ birdsCount: 500, eggsProduced: 420, brokenEggs: 5 })
    ).toBe(84);
  });
});

describe("assignQualityGrade", () => {
  it("grades A when broken ratio is low", () => {
    expect(
      assignQualityGrade({ birdsCount: 500, eggsProduced: 420, brokenEggs: 5 })
    ).toBe("A");
  });

  it("grades C when broken ratio is high", () => {
    expect(
      assignQualityGrade({ birdsCount: 500, eggsProduced: 420, brokenEggs: 40 })
    ).toBe("C");
  });
});
