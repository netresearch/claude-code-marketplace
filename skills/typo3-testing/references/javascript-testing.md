# JavaScript and CKEditor Testing

**Purpose:** Testing patterns for TYPO3 CKEditor plugins, JavaScript functionality, and frontend code

## Overview

While TYPO3 extensions are primarily PHP, many include JavaScript for:
- CKEditor custom plugins and features
- Backend module interactions
- Frontend enhancements
- RTE (Rich Text Editor) extensions

This guide covers testing patterns for JavaScript code in TYPO3 extensions.

## CKEditor Plugin Testing

### Testing Model Attributes

CKEditor plugins define model attributes that must be properly handled through upcast (view→model) and downcast (model→view) conversions.

**Example from t3x-rte_ckeditor_image:**

The plugin added a `noScale` attribute to prevent image processing. This requires testing:

1. **Attribute schema registration**
2. **Upcast conversion** (HTML → CKEditor model)
3. **Downcast conversion** (CKEditor model → HTML)
4. **UI interaction** (dialog checkbox)

### Test Structure Pattern

```javascript
// Resources/Public/JavaScript/Plugins/__tests__/typo3image.test.js

import { typo3image } from '../typo3image';

describe('TYPO3 Image Plugin', () => {
    let editor;

    beforeEach(async () => {
        editor = await createTestEditor();
    });

    afterEach(() => {
        return editor.destroy();
    });

    describe('Model Schema', () => {
        it('should allow noScale attribute', () => {
            const schema = editor.model.schema;
            expect(schema.checkAttribute('typo3image', 'noScale')).toBe(true);
        });
    });

    describe('Upcast Conversion', () => {
        it('should read data-noscale from HTML', () => {
            const html = '<img src="test.jpg" data-noscale="true" />';
            editor.setData(html);

            const imageElement = editor.model.document.getRoot()
                .getChild(0);

            expect(imageElement.getAttribute('noScale')).toBe(true);
        });

        it('should handle missing data-noscale attribute', () => {
            const html = '<img src="test.jpg" />';
            editor.setData(html);

            const imageElement = editor.model.document.getRoot()
                .getChild(0);

            expect(imageElement.getAttribute('noScale')).toBe(false);
        });
    });

    describe('Downcast Conversion', () => {
        it('should write data-noscale to HTML when enabled', () => {
            editor.model.change(writer => {
                const imageElement = writer.createElement('typo3image', {
                    src: 'test.jpg',
                    noScale: true
                });
                writer.insert(imageElement, editor.model.document.getRoot(), 0);
            });

            const html = editor.getData();
            expect(html).toContain('data-noscale="true"');
        });

        it('should omit data-noscale when disabled', () => {
            editor.model.change(writer => {
                const imageElement = writer.createElement('typo3image', {
                    src: 'test.jpg',
                    noScale: false
                });
                writer.insert(imageElement, editor.model.document.getRoot(), 0);
            });

            const html = editor.getData();
            expect(html).not.toContain('data-noscale');
        });
    });
});
```

### Testing data-* Attributes

Many TYPO3 CKEditor plugins use `data-*` attributes to pass information from editor to server-side rendering.

**Common Patterns:**

```javascript
describe('data-* Attribute Handling', () => {
    it('should preserve TYPO3-specific attributes', () => {
        const testCases = [
            { attr: 'data-htmlarea-file-uid', value: '123' },
            { attr: 'data-htmlarea-file-table', value: 'sys_file' },
            { attr: 'data-htmlarea-zoom', value: 'true' },
            { attr: 'data-noscale', value: 'true' },
            { attr: 'data-alt-override', value: 'false' },
            { attr: 'data-title-override', value: 'true' }
        ];

        testCases.forEach(({ attr, value }) => {
            const html = `<img src="test.jpg" ${attr}="${value}" />`;
            editor.setData(html);

            // Verify upcast preserves attribute
            const output = editor.getData();
            expect(output).toContain(`${attr}="${value}"`);
        });
    });

    it('should handle boolean data attributes', () => {
        // Test true value
        editor.setData('<img src="test.jpg" data-noscale="true" />');
        let imageElement = editor.model.document.getRoot().getChild(0);
        expect(imageElement.getAttribute('noScale')).toBe(true);

        // Test false value
        editor.setData('<img src="test.jpg" data-noscale="false" />');
        imageElement = editor.model.document.getRoot().getChild(0);
        expect(imageElement.getAttribute('noScale')).toBe(false);

        // Test missing attribute
        editor.setData('<img src="test.jpg" />');
        imageElement = editor.model.document.getRoot().getChild(0);
        expect(imageElement.getAttribute('noScale')).toBe(false);
    });
});
```

### Testing Dialog UI

CKEditor dialogs require testing user interactions:

```javascript
describe('Image Dialog', () => {
    let dialog, $checkbox;

    beforeEach(() => {
        dialog = createImageDialog(editor);
        $checkbox = dialog.$el.find('#checkbox-noscale');
    });

    it('should display noScale checkbox', () => {
        expect($checkbox.length).toBe(1);
        expect($checkbox.parent('label').text())
            .toContain('Use original file (noScale)');
    });

    it('should set noScale attribute when checkbox checked', () => {
        $checkbox.prop('checked', true);
        dialog.save();

        const imageElement = getSelectedImage(editor);
        expect(imageElement.getAttribute('noScale')).toBe(true);
    });

    it('should remove noScale attribute when checkbox unchecked', () => {
        // Start with noScale enabled
        const imageElement = getSelectedImage(editor);
        editor.model.change(writer => {
            writer.setAttribute('noScale', true, imageElement);
        });

        // Uncheck and save
        $checkbox.prop('checked', false);
        dialog.save();

        expect(imageElement.getAttribute('noScale')).toBe(false);
    });

    it('should load checkbox state from existing attribute', () => {
        const imageElement = getSelectedImage(editor);
        editor.model.change(writer => {
            writer.setAttribute('noScale', true, imageElement);
        });

        dialog = createImageDialog(editor);
        $checkbox = dialog.$el.find('#checkbox-noscale');

        expect($checkbox.prop('checked')).toBe(true);
    });
});
```

## JavaScript Test Frameworks

### Jest (Recommended)

**Installation:**
```bash
npm install --save-dev jest @babel/preset-env
```

**Configuration (jest.config.js):**
```javascript
module.exports = {
    testEnvironment: 'jsdom',
    transform: {
        '^.+\\.js$': 'babel-jest'
    },
    moduleNameMapper: {
        '\\.(css|less|scss)$': 'identity-obj-proxy'
    },
    collectCoverageFrom: [
        'Resources/Public/JavaScript/**/*.js',
        '!Resources/Public/JavaScript/**/*.test.js',
        '!Resources/Public/JavaScript/**/__tests__/**'
    ],
    coverageThreshold: {
        global: {
            branches: 70,
            functions: 70,
            lines: 70,
            statements: 70
        }
    }
};
```

### Mocha + Chai

Alternative for projects already using Mocha:

```javascript
// test/javascript/typo3image.test.js
const { expect } = require('chai');
const { JSDOM } = require('jsdom');

describe('TYPO3 Image Plugin', function() {
    let editor;

    beforeEach(async function() {
        const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
        global.window = dom.window;
        global.document = window.document;

        editor = await createTestEditor();
    });

    it('should handle noScale attribute', function() {
        // Test implementation
    });
});
```

## Testing Best Practices

### 1. Isolate Editor Instance

Each test should use a fresh editor instance:

```javascript
async function createTestEditor() {
    const div = document.createElement('div');
    document.body.appendChild(div);

    const editor = await ClassicEditor.create(div, {
        plugins: [Typo3Image, /* other plugins */],
        typo3image: {
            /* plugin config */
        }
    });

    return editor;
}
```

### 2. Clean Up After Tests

Prevent memory leaks and DOM pollution:

```javascript
afterEach(async () => {
    if (editor) {
        await editor.destroy();
        editor = null;
    }

    // Clean up any test DOM elements
    document.body.innerHTML = '';
});
```

### 3. Test Both Happy Path and Edge Cases

```javascript
describe('Attribute Validation', () => {
    it('should handle valid boolean values', () => {
        // Happy path
    });

    it('should handle invalid attribute values', () => {
        const html = '<img src="test.jpg" data-noscale="invalid" />';
        editor.setData(html);

        // Should default to false
        const imageElement = editor.model.document.getRoot().getChild(0);
        expect(imageElement.getAttribute('noScale')).toBe(false);
    });

    it('should handle malformed HTML', () => {
        const html = '<img src="test.jpg" data-noscale>';  // Missing value
        // Test graceful handling
    });
});
```

### 4. Mock Backend Interactions

For plugins that communicate with TYPO3 backend:

```javascript
beforeEach(() => {
    global.fetch = jest.fn(() =>
        Promise.resolve({
            json: () => Promise.resolve({ success: true })
        })
    );
});

afterEach(() => {
    global.fetch.mockRestore();
});

it('should fetch image metadata from backend', async () => {
    await plugin.fetchImageMetadata(123);

    expect(fetch).toHaveBeenCalledWith(
        '/typo3/ajax/image/metadata/123',
        expect.any(Object)
    );
});
```

## Integration with PHP Tests

JavaScript tests complement PHP unit tests:

**PHP Side (Backend):**
```php
// Tests/Unit/Controller/ImageRenderingControllerTest.php
public function testNoScaleAttribute(): void
{
    $attributes = ['data-noscale' => 'true'];
    $result = $this->controller->render($attributes);

    // Verify noScale parameter passed to imgResource
    $this->assertStringContainsString('noScale=1', $result);
}
```

**JavaScript Side (Frontend):**
```javascript
// Resources/Public/JavaScript/__tests__/typo3image.test.js
it('should generate data-noscale attribute', () => {
    // Verify attribute is created in editor
    editor.model.change(writer => {
        const img = writer.createElement('typo3image', {
            noScale: true
        });
        writer.insert(img, editor.model.document.getRoot(), 0);
    });

    expect(editor.getData()).toContain('data-noscale="true"');
});
```

**Together:** These tests ensure end-to-end functionality from editor UI → HTML attribute → PHP backend processing.

## CI/CD Integration

Add JavaScript tests to your CI pipeline:

**package.json:**
```json
{
    "scripts": {
        "test": "jest",
        "test:coverage": "jest --coverage",
        "test:watch": "jest --watch"
    },
    "devDependencies": {
        "jest": "^29.0.0",
        "@babel/preset-env": "^7.20.0"
    }
}
```

**GitHub Actions:**
```yaml
- name: Run JavaScript tests
  run: |
    npm install
    npm run test:coverage

- name: Upload JS coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
    flags: javascript
```

## Example: Complete Test Suite

See `t3x-rte_ckeditor_image` for a real-world example:

```
t3x-rte_ckeditor_image/
├── Resources/Public/JavaScript/
│   └── Plugins/
│       ├── typo3image.js              # Main plugin
│       └── __tests__/
│           └── typo3image.test.js     # JavaScript tests
└── Tests/Unit/
    └── Controller/
        └── ImageRenderingControllerTest.php  # PHP tests
```

**Key Lessons:**
1. Test attribute schema registration
2. Test upcast/downcast conversions separately
3. Test UI interactions (checkboxes, inputs)
4. Test data-* attribute preservation
5. Clean up editor instances to prevent leaks
6. Mock backend API calls
7. Coordinate with PHP tests for full coverage

## Troubleshooting

### Tests Pass Locally but Fail in CI

**Cause:** DOM environment differences

**Solution:**
```javascript
// jest.config.js
module.exports = {
    testEnvironment: 'jsdom',
    testEnvironmentOptions: {
        url: 'http://localhost'
    }
};
```

### Memory Leaks in Test Suite

**Cause:** Editor instances not properly destroyed

**Solution:**
```javascript
afterEach(async () => {
    if (editor && !editor.state === 'destroyed') {
        await editor.destroy();
    }
    editor = null;
});
```

### Async Test Failures

**Cause:** Not waiting for editor initialization

**Solution:**
```javascript
beforeEach(async () => {
    editor = await ClassicEditor.create(/* ... */);
    // ☝️ await is critical
});
```

## References

- [CKEditor 5 Testing](https://ckeditor.com/docs/ckeditor5/latest/framework/guides/contributing/testing-environment.html)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [TYPO3 RTE CKEditor Image](https://github.com/netresearch/t3x-rte_ckeditor_image)
