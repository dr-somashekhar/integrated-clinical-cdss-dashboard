# Contributing to the Integrated Clinical CDSS

First, thank you for considering contributing to this project! Open-source collaboration is the foundation of reproducible translational research.

## 🔬 Scope of Contributions
We welcome contributions that improve the computational efficiency, statistical rigor, or clinical relevance of this pipeline. This includes:
* Corrections or additions to the clinical formulas and medication-safety rules (cite the guideline or paper).
* Support for new clinical covariates or risk indices.
* Bug fixes, tests, accessibility and deployment improvements.

## 🛠️ Pull Request (PR) Process
1. **Fork** the repository and create your feature branch (`git checkout -b feature/Advanced-Imputation`).
2. **Commit** your changes with descriptive messages (`git commit -m 'Added Random Forest imputation method'`).
3. **Test** your code. Put clinical logic in `R/` as pure functions, add `testthat` cases in `tests/testthat/`, and run `Rscript tests/testthat.R`. CI runs the same tests.
4. **Push** to the branch (`git push origin feature/Advanced-Imputation`).
5. **Open a Pull Request** against the `main` branch. 

## ⚖️ Clinical Data Standards
If your contribution involves simulated or sample patient datasets:
* **No PHI:** Ensure absolute compliance with HIPAA and GDPR. Never upload Protected Health Information.
* **Reproducibility:** Set seeds (e.g., `set.seed(2026)`) for any stochastic processes, Monte Carlo simulations, or ML training splits.
