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
