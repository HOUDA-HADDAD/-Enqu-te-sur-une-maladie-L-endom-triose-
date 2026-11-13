import pandas as pd
import os

FILE_PATH = "data/processed/expression_clean.tsv"

def test_fichier_existe():
    assert os.path.exists(FILE_PATH)

def test_dimensions():
    df = pd.read_csv(FILE_PATH, sep='\t')
    assert df.shape == (48701, 338)

def test_valeurs_manquantes():
    df = pd.read_csv(FILE_PATH, sep='\t')
    assert df.isnull().sum().sum() == 0

def test_deg_csv_cree_et_colonnes():
    deg_file = "results/deg.csv"
    assert os.path.exists(deg_file), "Le fichier feg.csv n'a pas ete cree."
    df = pd.read_csv(deg_file)
    assert 'log2FC' in df.columns, "La colonne log2FC manque."
    assert 'p_adj_BH' in df.columns, "La colonne p_adj_BH manque."

def test_seuils_respectes():
    deg_file = "results/deg.csv"
    assert os.path.exists(deg_file), "Le fichier deg.csv n'a pas ete cree."
    df = pd.read_csv(deg_file)
    assert (df['p_adj_BH'] < 0.05).all(), "Un gene depasse le seuil de p ajustee."
    assert (df['log2FC'].abs() >= 1.0).all(), "Un gene est sous le seuil de log2FC."

def test_graphiques_generes():
    assert os.path.exists("results/boxplot.png") or os.path.exists("results/heatmap.png"), "Aucun graphique genere."
