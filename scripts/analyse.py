#!/usr/bin/env python3
import argparse
import pandas as pd
import numpy as np
from scipy import stats
from statsmodels.stats.multitest import multipletests
import json
import os

def main():
    parser = argparse.ArgumentParser(description="Analyse d'expression génique")
    parser.add_argument("--input", required=True)
    parser.add_argument("--meta", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--lfc", type=float, default=1.0)
    parser.add_argument("--alpha", type=float, default=0.05)
    args = parser.parse_args()

    print("Chargement des données...")
    df_expr = pd.read_csv(args.input, sep='\t', index_col=0)
    df_meta = pd.read_csv(args.meta, sep='\t')

    lesion_indices = [i for i, group in enumerate(df_meta['Group']) if 'endometrium' not in group.lower()]
    control_indices = [i for i, group in enumerate(df_meta['Group']) if 'endometrium' in group.lower()]
    expr_cols = df_expr.columns.tolist()

    samples_lesion = [expr_cols[i+2] for i in lesion_indices if i+2 < len(expr_cols)]
    samples_control = [expr_cols[i+2] for i in control_indices if i+2 < len(expr_cols)]

    print(f"Échantillons Lésion : {len(samples_lesion)}")
    print(f"Échantillons Contrôle : {len(samples_control)}")

    data_lesion = df_expr[samples_lesion].apply(pd.to_numeric, errors='coerce')
    data_control = df_expr[samples_control].apply(pd.to_numeric, errors='coerce')

    mean_lesion = data_lesion.mean(axis=1)
    mean_control = data_control.mean(axis=1)
    log2fc = mean_lesion - mean_control

    print("Test statistique (Welch)...")
    t_stat, p_values = stats.ttest_ind(data_lesion, data_control, axis=1, equal_var=False, nan_policy='omit')

    print("Correction Benjamini-Hochberg...")
    valid_pvals = p_values[~np.isnan(p_values)]
    reject, p_adj, _, _ = multipletests(valid_pvals, alpha=args.alpha, method='fdr_bh')

    p_adj_full = np.full_like(p_values, np.nan)
    p_adj_full[~np.isnan(p_values)] = p_adj

    results = pd.DataFrame({
        'Gene': df_expr.index, 'mean_Lesion': mean_lesion, 'mean_Control': mean_control,
        'log2FC': log2fc, 'p_value': p_values, 'p_adj_BH': p_adj_full
    })

    # حفظ كل النتائج (بدون فلترة) لكي نرى أفضل الجينات
    os.makedirs(args.out, exist_ok=True)
    results.to_csv(os.path.join(args.out, 'all_results.csv'), index=False)

    # تطبيق الفلترة
    mask = (results['log2FC'].abs() >= args.lfc) & (results['p_adj_BH'] < args.alpha)
    deg_results = results[mask].copy()
    deg_results.to_csv(os.path.join(args.out, 'deg.csv'), index=False)

    summary = {
        "total_genes_tested": int(len(results)),
        "significant_genes": int(len(deg_results)),
        "thresholds": {"log2FC": args.lfc, "p_adj": args.alpha},
        "samples_used": {"lesion": len(samples_lesion), "control": len(samples_control)}
    }
    with open(os.path.join(args.out, 'summary.json'), 'w') as f:
        json.dump(summary, f, indent=4)

    print(f"Terminé ! {len(deg_results)} gènes significatifs trouvés (seuil lfc={args.lfc}, alpha={args.alpha}).")

if __name__ == "__main__":
    main()
