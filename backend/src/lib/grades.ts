export function pctToGpaPoints(pct: number): number {
  if (pct >= 93) return 4.0;
  if (pct >= 90) return 3.7;
  if (pct >= 87) return 3.3;
  if (pct >= 83) return 3.0;
  if (pct >= 80) return 2.7;
  if (pct >= 77) return 2.3;
  if (pct >= 73) return 2.0;
  if (pct >= 70) return 1.7;
  if (pct >= 67) return 1.3;
  if (pct >= 65) return 1.0;
  return 0.0;
}

export function letterGrade(pct: number): string {
  if (pct >= 93) return "A";
  if (pct >= 90) return "A-";
  if (pct >= 87) return "B+";
  if (pct >= 83) return "B";
  if (pct >= 80) return "B-";
  if (pct >= 77) return "C+";
  if (pct >= 73) return "C";
  if (pct >= 70) return "C-";
  if (pct >= 67) return "D+";
  if (pct >= 60) return "D";
  return "F";
}

type GradedItem = { gradePct: number | null; weight: number | null };

export function courseAverage(items: GradedItem[]): number | null {
  const graded = items.filter((a) => a.gradePct != null);
  if (graded.length === 0) return null;

  const hasWeights = graded.some((a) => a.weight != null && a.weight > 0);

  if (hasWeights) {
    let wSum = 0;
    let wTotal = 0;
    for (const a of graded) {
      const w = a.weight ?? 1;
      wSum += a.gradePct! * w;
      wTotal += w;
    }
    return wTotal > 0 ? wSum / wTotal : null;
  }

  const sum = graded.reduce((acc, a) => acc + a.gradePct!, 0);
  return sum / graded.length;
}

export function creditWeightedGpa(
  courses: Array<{ credits: number; averagePct: number }>,
): number | null {
  if (courses.length === 0) return null;

  let totalPoints = 0;
  let totalCredits = 0;
  for (const c of courses) {
    totalPoints += pctToGpaPoints(c.averagePct) * c.credits;
    totalCredits += c.credits;
  }
  return totalCredits > 0 ? totalPoints / totalCredits : null;
}

/**
 * Computes the average grade needed on remaining (ungraded) work
 * to achieve a target overall percentage in a course.
 */
export function requiredGradeForTarget(
  graded: Array<{ gradePct: number; weight: number | null }>,
  ungraded: Array<{ weight: number | null }>,
  targetPct: number,
): { requiredPct: number; achievable: boolean } | null {
  if (ungraded.length === 0) return null;

  const hasWeights =
    graded.some((a) => a.weight != null && a.weight > 0) ||
    ungraded.some((a) => a.weight != null && a.weight > 0);

  if (hasWeights) {
    const earnedSum = graded.reduce(
      (acc, a) => acc + a.gradePct * (a.weight ?? 0),
      0,
    );
    const earnedWeight = graded.reduce((acc, a) => acc + (a.weight ?? 0), 0);
    const remainingWeight = ungraded.reduce(
      (acc, a) => acc + (a.weight ?? 0),
      0,
    );
    if (remainingWeight === 0) return null;

    const required =
      (targetPct * (earnedWeight + remainingWeight) - earnedSum) /
      remainingWeight;
    return {
      requiredPct: Math.round(required * 10) / 10,
      achievable: required >= 0 && required <= 100,
    };
  }

  const sumGraded = graded.reduce((acc, a) => acc + a.gradePct, 0);
  const totalCount = graded.length + ungraded.length;
  const required = (targetPct * totalCount - sumGraded) / ungraded.length;
  return {
    requiredPct: Math.round(required * 10) / 10,
    achievable: required >= 0 && required <= 100,
  };
}
