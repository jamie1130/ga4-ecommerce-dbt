"""
Is the desktop vs. mobile conversion gap real, and how big a test would we need to detect a lift?

Reads the dbt mart `fct_funnel_by_channel`, then:
  1. Two-proportion z-test on session conversion rate (desktop vs. mobile)
  2. 95% confidence interval for the difference
  3. Sample size per arm needed to detect a given relative lift in an A/B test

Usage:
    pip install google-cloud-bigquery pandas db-dtypes
    python notebooks/conversion_significance.py --project YOUR_GCP_PROJECT_ID --dataset ga4_dbt_marts
"""
import argparse
import math

from google.cloud import bigquery


def norm_cdf(x: float) -> float:
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))


def norm_ppf(p: float) -> float:
    # Acklam's rational approximation; accurate to ~1e-9, avoids a scipy dependency.
    a = [-3.969683028665376e01, 2.209460984245205e02, -2.759285104469687e02,
         1.383577518672690e02, -3.066479806614716e01, 2.506628277459239e00]
    b = [-5.447609879822406e01, 1.615858368580409e02, -1.556989798598866e02,
         6.680131188771972e01, -1.328068155288572e01]
    c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e00,
         -2.549732539343734e00, 4.374664141464968e00, 2.938163982698783e00]
    d = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e00,
         3.754408661907416e00]
    lo, hi = 0.02425, 1 - 0.02425
    if p < lo:
        q = math.sqrt(-2 * math.log(p))
        return (((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) / ((((d[0]*q+d[1])*q+d[2])*q+d[3])*q+1)
    if p > hi:
        return -norm_ppf(1 - p)
    q = p - 0.5
    r = q * q
    return (((((a[0]*r+a[1])*r+a[2])*r+a[3])*r+a[4])*r+a[5])*q / (((((b[0]*r+b[1])*r+b[2])*r+b[3])*r+b[4])*r+1)


def two_proportion_test(x1, n1, x2, n2, alpha=0.05):
    p1, p2 = x1 / n1, x2 / n2
    pooled = (x1 + x2) / (n1 + n2)
    se_pooled = math.sqrt(pooled * (1 - pooled) * (1 / n1 + 1 / n2))
    z = (p1 - p2) / se_pooled
    p_value = 2 * (1 - norm_cdf(abs(z)))
    se_diff = math.sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
    z_crit = norm_ppf(1 - alpha / 2)
    ci = (p1 - p2 - z_crit * se_diff, p1 - p2 + z_crit * se_diff)
    return p1, p2, z, p_value, ci


def sample_size_per_arm(baseline, relative_lift, alpha=0.05, power=0.8):
    p1 = baseline
    p2 = baseline * (1 + relative_lift)
    z_a, z_b = norm_ppf(1 - alpha / 2), norm_ppf(power)
    p_bar = (p1 + p2) / 2
    n = ((z_a * math.sqrt(2 * p_bar * (1 - p_bar)) + z_b * math.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2) / (p2 - p1) ** 2
    return math.ceil(n)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--dataset", default="ga4_dbt_marts")
    args = ap.parse_args()

    client = bigquery.Client(project=args.project)
    df = client.query(f"""
        select device_category, sum(sessions) as sessions, sum(purchase_sessions) as conversions
        from `{args.project}.{args.dataset}.fct_funnel_by_channel`
        where device_category in ('desktop', 'mobile')
        group by 1
    """).to_dataframe().set_index("device_category")

    d, m = df.loc["desktop"], df.loc["mobile"]
    p1, p2, z, p, ci = two_proportion_test(d.conversions, d.sessions, m.conversions, m.sessions)
    print(f"Desktop conversion: {p1:.3%}  ({int(d.conversions):,} / {int(d.sessions):,})")
    print(f"Mobile conversion:  {p2:.3%}  ({int(m.conversions):,} / {int(m.sessions):,})")
    print(f"Difference: {p1 - p2:+.3%}   95% CI [{ci[0]:+.3%}, {ci[1]:+.3%}]")
    print(f"z = {z:.2f}, p = {p:.4f} -> {'significant' if p < 0.05 else 'not significant'} at alpha = 0.05")

    print("\nSessions needed per arm to detect a relative lift in desktop conversion (alpha 0.05, power 0.8):")
    for lift in (0.05, 0.10, 0.20):
        print(f"  {lift:>4.0%} lift: {sample_size_per_arm(p1, lift):,} sessions per arm")


if __name__ == "__main__":
    main()
