import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

DATA_PATH = "data/processed/expression_clean.tsv"
RESULTS_DIR = "results"

os.makedirs(RESULTS_DIR, exist_ok=True)

print("reading data")
df = pd.read_csv(DATA_PATH, sep='\t', index_col=0)
df = df.select_dtypes(include='number')

print("designing Boxplot")
plt.figure(figsize=(12, 6))
sns.boxplot(data=df.iloc[:, :20])
plt.title("Distribution de l'expression (20 premiers echantillons)")
plt.xticks(rotation=90)
plt.tight_layout()
plt.savefig(f"{RESULTS_DIR}/boxplot.png")
plt.close()

print("designing Heatmap ( more than 50 gen )")
top_genes = df.var(axis=1).nlargest(50).index
df_top = df.loc[top_genes]

plt.figure(figsize=(10, 8))
sns.heatmap(df_top, cmap="viridis", yticklabels=False, xticklabels=False)
plt.title("Heatmap des 50 genes les plus variables")
plt.tight_layout()
plt.savefig(f"{RESULTS_DIR}/heatmap.png")
plt.close()

print("resuls are ready")
