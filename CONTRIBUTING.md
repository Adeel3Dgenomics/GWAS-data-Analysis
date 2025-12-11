# Contributing to GWAS Analysis Pipeline

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- **Clear title** describing the problem
- **Steps to reproduce** the bug
- **Expected behavior** vs actual behavior
- **Environment details** (PLINK version, OS, memory, etc.)
- **Log files** if available

### Suggesting Enhancements

For feature requests:
- Explain the **use case**
- Describe the **expected behavior**
- Provide **examples** if applicable
- Discuss potential **implementation approaches**

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation
4. **Test thoroughly**
   - Test with different data sizes
   - Verify all fallback mechanisms
   - Check edge cases
5. **Commit with clear messages**
   ```bash
   git commit -m "Add feature: description of changes"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

## 📝 Code Style Guidelines

### Shell Scripts (Bash)
- Use 4-space indentation
- Add comments for each major section
- Use descriptive variable names in UPPERCASE for globals
- Include error handling with `|| error_exit`
- Log important steps with timestamps

```bash
# Good example
log_message "[Step X/18] Performing analysis..."
plink --bfile "$INPUT" \
      --out "$OUTPUT" \
      --allow-no-sex || error_exit "Analysis failed"
```

### Python Scripts
- Follow PEP 8 style guide
- Use docstrings for functions
- Add type hints when appropriate
- Handle exceptions gracefully

```python
def process_data(input_file: str, output_dir: str) -> None:
    """
    Process GWAS data and generate outputs.
    
    Args:
        input_file: Path to input association file
        output_dir: Directory for output files
    """
    try:
        # Implementation
        pass
    except Exception as e:
        print(f"Error: {e}")
```

### Documentation
- Update README.md for user-facing changes
- Update CHANGELOG.md for all changes
- Add inline comments for complex logic
- Include usage examples

## 🧪 Testing Guidelines

### Test Your Changes
- Run on small test datasets first
- Verify with realistic data sizes
- Test all fallback mechanisms
- Check memory usage
- Verify output file formats

### Test Cases to Consider
- Missing data scenarios
- Edge cases (0 SNPs, 0 cases, etc.)
- Large datasets (>1M SNPs)
- Incomplete/corrupted input files
- Missing optional dependencies

## 📋 Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] Changes are well documented
- [ ] README updated if needed
- [ ] CHANGELOG updated
- [ ] Tested with sample data
- [ ] No breaking changes (or documented if necessary)
- [ ] Commit messages are clear

## 🎯 Development Priorities

### High Priority
- PLINK 2.0 compatibility
- Improved error messages
- Performance optimization for large datasets
- Additional visualization options

### Medium Priority
- Imputation workflow integration
- Meta-analysis support
- Interactive HTML reports
- Automated testing framework

### Nice to Have
- GUI interface
- Cloud deployment support
- Docker containerization
- Snakemake workflow version

## 💬 Communication

- **Questions:** Open a GitHub Discussion
- **Bugs:** Create an Issue
- **Features:** Start with a Discussion, then create Issue
- **Email:** muhammad.muzammal@bs.qau.edu.pk

## 📜 Code of Conduct

### Our Standards
- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Accept criticism gracefully
- Prioritize community benefit

### Unacceptable Behavior
- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information

## 🏆 Recognition

Contributors will be:
- Listed in the project README
- Mentioned in release notes
- Credited in publications using this work (when applicable)

## ❓ Questions?

Don't hesitate to ask! Open a discussion or send an email.

---

Thank you for contributing to better GWAS analysis tools! 🎉

