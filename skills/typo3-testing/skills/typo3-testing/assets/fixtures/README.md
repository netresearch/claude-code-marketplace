# CSV Fixture Templates

Example CSV fixtures for TYPO3 functional tests.

## Usage

Place CSV fixtures in your test directory:
```
Tests/Functional/
├── Fixtures/
│   ├── be_users.csv
│   ├── pages.csv
│   └── tt_content.csv
└── Repository/
    └── MyRepositoryTest.php
```

Import fixtures in your test:
```php
protected function setUp(): void
{
    parent::setUp();

    $this->importCSVDataSet(__DIR__ . '/Fixtures/be_users.csv');
    $this->importCSVDataSet(__DIR__ . '/Fixtures/pages.csv');
}
```

## CSV Format Rules

1. **Header row is required** - Column names must match database field names
2. **Quote all values** - Use double quotes around all values
3. **Include required fields** - `uid`, `pid`, timestamps (`tstamp`, `crdate`)
4. **Use consistent timestamps** - `1700000000` is Nov 14, 2023 (arbitrary but consistent)

## Common Fixtures

| File | Description |
|------|-------------|
| `be_users.csv` | Backend users (admin, editor) |
| `pages.csv` | Page tree structure |
| `tt_content.csv` | Content elements |
| `sys_category.csv` | Categories with hierarchy |

## Password Hashes

The default password hash in `be_users.csv` is for the password `password`.

To generate a new hash:
```php
$hashFactory = GeneralUtility::makeInstance(\TYPO3\CMS\Core\Crypto\PasswordHashing\PasswordHashFactory::class);
$hash = $hashFactory->getDefaultHashInstance('BE')->getHashedPassword('your-password');
```

## Tips

- **Minimal data** - Only include fields needed for your test
- **Explicit UIDs** - Always set explicit UIDs for reliable references
- **Isolation** - Each test class should have its own fixture set
- **Reset** - Functional tests reset the database between tests automatically

## Extension-Specific Fixtures

For custom tables, create CSV matching your table structure:

```csv
"uid","pid","title","custom_field","tstamp","crdate"
1,0,"Record 1","value1",1700000000,1700000000
2,0,"Record 2","value2",1700000000,1700000000
```

Ensure the table is imported in your extension's `ext_tables.sql`.
