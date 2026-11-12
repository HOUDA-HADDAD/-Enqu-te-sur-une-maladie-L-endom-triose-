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
    assert 'padj' in df.columns, "La colonne padj manque."

def test_seuils_respectes():
    deg_file = "results/deg.csv"
    if os.path.exists(deg_file):
       df = pd.read_csv(deg_file)
       genes_valides = df[(df['padj'] < 0.05) & (df['log2FC'].abs() >= 1.0)]
       assert not genes_valides.empty, "Les seuils ne sont pas respectes."

def test_graphiques_generes():
    assert os.path.exists("results/boxplot.png" or os.path.exists("results/heatmap.png"), "Aucun graphique n'a ete genere."

