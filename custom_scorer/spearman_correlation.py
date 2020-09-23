"""Spearman's Rank Correlation Coefficient"""
import typing
import numpy as np
import scipy
from h2oaicore.metrics import CustomScorer

class Spearman_Correlation(CustomScorer):
    _description = "Spearman's Rank Correlation Coefficient"
    _regression = True
    _maximize = True
    _perfect_score = 1.
    _supports_sample_weight = False
    _display_name = "SpearmanR"

    def score(self,
              actual: np.array,
              predicted: np.array,
              sample_weight: typing.Optional[np.array] = None,
              labels: typing.Optional[np.array] = None) -> float:
        if sample_weight is None:
            sample_weight = np.ones(actual.shape[0])
        
        # Spearman's Rank Correlation
        return scipy.stats.spearmanr(actual, predicted)[0]
