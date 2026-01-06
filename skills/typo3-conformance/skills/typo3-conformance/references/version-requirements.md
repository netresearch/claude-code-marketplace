# TYPO3 and PHP Version Requirements

**Purpose:** Definitive version compatibility matrix for TYPO3 conformance checking
**Last Updated:** 2025-01-18

## Official Version Support Matrix

### TYPO3 12 LTS

**Release:** April 2022
**End of Life:** October 2026
**PHP Support:** 8.1 - 8.4

| PHP Version | Support Status | Since TYPO3 Version |
|------------|----------------|---------------------|
| 8.1 | ✅ Supported | 12.0.0 |
| 8.2 | ✅ Supported | 12.1.0 |
| 8.3 | ✅ Supported | 12.4.0 |
| 8.4 | ✅ Supported | 12.4.24 (Dec 2024) |

**Minimum Requirements:**
- PHP: 8.1.0
- Database: MariaDB 10.4+ / MySQL 8.0+ / PostgreSQL 10.0+ / SQLite 3.8.3+

### TYPO3 13 LTS

**Release:** October 2024
**End of Life:** April 2028
**PHP Support:** 8.2 - 8.4

| PHP Version | Support Status | Since TYPO3 Version |
|------------|----------------|---------------------|
| 8.1 | ❌ Not Supported | - |
| 8.2 | ✅ Supported | 13.0.0 |
| 8.3 | ✅ Supported | 13.0.0 |
| 8.4 | ✅ Supported | 13.4.0 |

**Minimum Requirements:**
- PHP: 8.2.0
- Database: MariaDB 10.4+ / MySQL 8.0+ / PostgreSQL 10.0+ / SQLite 3.8.3+

## Conformance Checker Standards

The TYPO3 conformance checker validates extensions against:

**Target Versions:**
- TYPO3: 12.4 LTS / 13.x
- PHP: 8.1 / 8.2 / 8.3 / 8.4
- PSR Standards: PSR-11 (DI), PSR-12 (Coding Style), PSR-14 (Events), PSR-15 (Middleware)

**Why This Range:**
- Covers both TYPO3 12 LTS and 13 LTS
- PHP 8.1+ ensures support for all modern PHP features used in TYPO3 extensions
- Extensions can target TYPO3 12 (PHP 8.1+) and/or TYPO3 13 (PHP 8.2+)

## Extension composer.json Examples

### TYPO3 12 LTS Only
```json
{
  "require": {
    "php": "^8.1 || ^8.2 || ^8.3 || ^8.4",
    "typo3/cms-core": "^12.4"
  }
}
```

### TYPO3 13 LTS Only
```json
{
  "require": {
    "php": "^8.2 || ^8.3 || ^8.4",
    "typo3/cms-core": "^13.4"
  }
}
```

### TYPO3 12 and 13 LTS (Recommended for New Extensions)
```json
{
  "require": {
    "php": "^8.2 || ^8.3 || ^8.4",
    "typo3/cms-core": "^12.4 || ^13.4"
  }
}
```

**Note:** When targeting both TYPO3 12 and 13, use PHP 8.2+ as minimum to satisfy TYPO3 13's requirements.

## PHP Feature Availability

### PHP 8.1 Features (TYPO3 12+)
- Enumerations
- Readonly properties
- First-class callable syntax
- New in initializers
- Pure intersection types
- Never return type
- Final class constants
- Fibers

### PHP 8.2 Features (TYPO3 13+)
- Readonly classes
- Disjunctive Normal Form (DNF) types
- Null, false, and true as standalone types
- Constants in traits
- Deprecated dynamic properties

### PHP 8.3 Features (TYPO3 12.4+ / 13+)
- Typed class constants
- Dynamic class constant fetch
- `#[\Override]` attribute
- `json_validate()` function

### PHP 8.4 Features (TYPO3 12.4.24+ / 13.4+)
- Property hooks
- Asymmetric visibility
- New array functions
- HTML5 support in DOM extension

## Migration Paths

### From TYPO3 11 to 12
1. Update PHP to 8.1+ (recommended: 8.2+)
2. Update extension to TYPO3 12 compatibility
3. Test thoroughly on PHP 8.2+ for future TYPO3 13 compatibility

### From TYPO3 12 to 13
1. Ensure PHP 8.2+ is already in use
2. Update TYPO3 dependencies to ^13.4
3. Remove deprecated API usage
4. Update Services.yaml for TYPO3 13 changes (if any)

## Deprecation Timeline

**PHP Versions:**
- PHP 8.0: End of Life - November 2023 (Not supported by TYPO3 12/13)
- PHP 8.1: Security fixes until November 2025
- PHP 8.2: Security fixes until December 2026
- PHP 8.3: Security fixes until December 2027
- PHP 8.4: Security fixes until December 2028

**Recommendation:** Target PHP 8.2+ for new extensions to ensure long-term support alignment with TYPO3 13 LTS lifecycle.

## References

- [TYPO3 12 System Requirements](https://docs.typo3.org/m/typo3/reference-coreapi/12.4/en-us/Installation/Index.html)
- [TYPO3 13 System Requirements](https://docs.typo3.org/m/typo3/reference-coreapi/13.4/en-us/Administration/Installation/SystemRequirements/Index.html)
- [PHP Release Cycles](https://www.php.net/supported-versions.php)
- [TYPO3 Roadmap](https://typo3.org/cms/roadmap)
