# CKEditor 5 TYPO3 Integration

## Overview

TYPO3 v12+ uses CKEditor 5 as the default Rich Text Editor. Integration is handled through:
- YAML-based RTE presets
- Custom module bundling
- PHP configuration hooks
- Processing rules for HTML sanitization

## Configuration Structure

### Directory Layout

```
EXT:my_extension/
├── Configuration/
│   └── RTE/
│       ├── Default.yaml         # Default preset
│       ├── Minimal.yaml         # Minimal preset
│       └── Full.yaml            # Full-featured preset
├── Resources/
│   └── Public/
│       └── JavaScript/
│           └── Ckeditor/
│               ├── Plugins/
│               │   └── MyPlugin.js
│               └── my-plugin-bundle.js
└── ext_localconf.php
```

### YAML Configuration

```yaml
# Configuration/RTE/MyPreset.yaml
editor:
  config:
    # Toolbar configuration
    toolbar:
      items:
        - heading
        - '|'
        - bold
        - italic
        - strikethrough
        - subscript
        - superscript
        - '|'
        - link
        - '|'
        - bulletedList
        - numberedList
        - '|'
        - blockQuote
        - insertTable
        - '|'
        - sourceEditing
        - '|'
        - undo
        - redo

    # Heading configuration
    heading:
      options:
        - { model: 'paragraph', title: 'Paragraph', class: 'ck-heading_paragraph' }
        - { model: 'heading1', view: 'h1', title: 'Heading 1', class: 'ck-heading_heading1' }
        - { model: 'heading2', view: 'h2', title: 'Heading 2', class: 'ck-heading_heading2' }
        - { model: 'heading3', view: 'h3', title: 'Heading 3', class: 'ck-heading_heading3' }
        - { model: 'heading4', view: 'h4', title: 'Heading 4', class: 'ck-heading_heading4' }

    # Table configuration
    table:
      contentToolbar:
        - tableColumn
        - tableRow
        - mergeTableCells
        - tableProperties
        - tableCellProperties

    # Link configuration
    link:
      allowCreatingEmptyLinks: false
      defaultProtocol: 'https://'
      decorators:
        openInNewTab:
          mode: manual
          label: 'Open in a new tab'
          defaultValue: false
          attributes:
            target: '_blank'
            rel: 'noopener noreferrer'

    # Style definitions
    style:
      definitions:
        - { name: 'Lead paragraph', element: 'p', classes: ['lead'] }
        - { name: 'Info box', element: 'div', classes: ['info-box'] }
        - { name: 'Warning box', element: 'div', classes: ['warning-box'] }

    # Import custom modules
    importModules:
      - '@typo3/rte-ckeditor/plugin/typo3-link.js'
      - '@typo3/rte-ckeditor/plugin/typo3-image.js'
      - '@vendor/my_extension/ckeditor/my-plugin-bundle.js'

# Processing configuration (HTML sanitization)
processing:
  mode: default
  allowTags:
    - a
    - abbr
    - b
    - blockquote
    - br
    - caption
    - cite
    - code
    - col
    - colgroup
    - dd
    - del
    - dfn
    - div
    - dl
    - dt
    - em
    - figcaption
    - figure
    - h1
    - h2
    - h3
    - h4
    - h5
    - h6
    - hr
    - i
    - img
    - ins
    - kbd
    - li
    - mark
    - ol
    - p
    - pre
    - q
    - s
    - samp
    - small
    - span
    - strong
    - sub
    - sup
    - table
    - tbody
    - td
    - tfoot
    - th
    - thead
    - tr
    - u
    - ul
    - var

  allowAttributes:
    # Global attributes
    - { attribute: 'class', elements: '*' }
    - { attribute: 'id', elements: '*' }
    - { attribute: 'title', elements: '*' }
    - { attribute: 'lang', elements: '*' }
    - { attribute: 'dir', elements: '*' }

    # Link attributes
    - { attribute: 'href', elements: 'a' }
    - { attribute: 'target', elements: 'a' }
    - { attribute: 'rel', elements: 'a' }
    - { attribute: 'download', elements: 'a' }

    # Image attributes
    - { attribute: 'src', elements: 'img' }
    - { attribute: 'alt', elements: 'img' }
    - { attribute: 'width', elements: 'img' }
    - { attribute: 'height', elements: 'img' }
    - { attribute: 'loading', elements: 'img' }

    # Table attributes
    - { attribute: 'colspan', elements: ['td', 'th'] }
    - { attribute: 'rowspan', elements: ['td', 'th'] }
    - { attribute: 'scope', elements: 'th' }

  # Transform tags
  transformTags:
    b: strong
    i: em

  # Deny tags explicitly
  denyTags:
    - script
    - style
    - iframe
    - object
    - embed
```

## PHP Registration

### Preset Registration

```php
<?php
// ext_localconf.php

defined('TYPO3') or die();

// Register RTE presets
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['my_extension_default'] =
    'EXT:my_extension/Configuration/RTE/Default.yaml';
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['my_extension_minimal'] =
    'EXT:my_extension/Configuration/RTE/Minimal.yaml';
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['my_extension_full'] =
    'EXT:my_extension/Configuration/RTE/Full.yaml';
```

### Custom Plugin Registration

```php
<?php
// ext_localconf.php

// Register CKEditor 5 plugin with stylesheets
$GLOBALS['TYPO3_CONF_VARS']['RTE']['CKEditor5']['plugins']['my-plugin'] = [
    'entryPoint' => 'EXT:my_extension/Resources/Public/JavaScript/Ckeditor/my-plugin-bundle.js',
    'stylesheets' => [
        'EXT:my_extension/Resources/Public/Css/Ckeditor/my-plugin.css',
    ],
];

// Alternative: Register via PageTsConfig for specific pages
\TYPO3\CMS\Core\Utility\ExtensionManagementUtility::addPageTSConfig('
    RTE.default.preset = my_extension_default
');
```

## TCA Configuration

### RTE in TCA

```php
<?php
// Configuration/TCA/Overrides/tt_content.php

$GLOBALS['TCA']['tt_content']['columns']['bodytext']['config'] = [
    'type' => 'text',
    'enableRichtext' => true,
    'richtextConfiguration' => 'my_extension_default',
];

// Conditional RTE configuration
$GLOBALS['TCA']['tt_content']['types']['textmedia']['columnsOverrides'] = [
    'bodytext' => [
        'config' => [
            'enableRichtext' => true,
            'richtextConfiguration' => 'my_extension_full',
        ],
    ],
];
```

### Custom Content Elements

```php
<?php
// Configuration/TCA/tx_myextension_content.php

return [
    'ctrl' => [
        'title' => 'LLL:EXT:my_extension/Resources/Private/Language/locallang_db.xlf:tx_myextension_content',
        'label' => 'title',
        // ... other ctrl settings
    ],
    'columns' => [
        'content' => [
            'label' => 'Content',
            'config' => [
                'type' => 'text',
                'enableRichtext' => true,
                'richtextConfiguration' => 'my_extension_default',
                'rows' => 15,
            ],
        ],
    ],
];
```

## JavaScript Module System

### ES Module Structure

```javascript
// Resources/Public/JavaScript/Ckeditor/Plugins/MyPlugin.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import { ButtonView } from '@ckeditor/ckeditor5-ui';

export default class MyPlugin extends Plugin {
    static get pluginName() {
        return 'MyPlugin';
    }

    init() {
        const editor = this.editor;

        // Add toolbar button
        editor.ui.componentFactory.add('myPluginButton', locale => {
            const buttonView = new ButtonView(locale);

            buttonView.set({
                label: 'My Plugin',
                tooltip: true,
                withText: true
            });

            buttonView.on('execute', () => {
                // Plugin action
                console.log('My plugin executed');
            });

            return buttonView;
        });
    }
}
```

### Bundle Entry Point

```javascript
// Resources/Public/JavaScript/Ckeditor/my-plugin-bundle.js
import MyPlugin from './Plugins/MyPlugin.js';

// Export for TYPO3 to register
export default {
    MyPlugin
};

// Or export individual plugins
export { MyPlugin };
```

### Import Map Configuration

```yaml
# Configuration/RTE/MyPreset.yaml
editor:
  config:
    importModules:
      # TYPO3 core modules use @ prefix
      - '@typo3/rte-ckeditor/plugin/typo3-link.js'

      # Custom modules use vendor prefix
      - '@vendor/my_extension/ckeditor/my-plugin-bundle.js'
```

## Processing Pipeline

### Understanding RTE Processing

```
User Input (Browser)
        ↓
   CKEditor 5 Model
        ↓
   CKEditor 5 View (HTML)
        ↓
   TYPO3 Processing (HTMLParser)
        ↓
   Database Storage
        ↓
   TYPO3 Processing (Frontend)
        ↓
   Frontend Output
```

### Custom Processing

```yaml
# Advanced processing configuration
processing:
  mode: default

  # Allow specific data attributes
  allowAttributes:
    - { attribute: 'data-*', elements: '*' }

  # Custom transformations
  HTMLparser_db:
    # Settings applied when saving to database
    allowTags: 'p,br,strong,em,a,ul,ol,li'
    denyTags: 'script,style'

  HTMLparser_rte:
    # Settings applied when loading into RTE
    stripEmptyTags: 1

  exitHTMLparser_db:
    # Settings after processing for database
    keepNonMatchedTags: 0
```

### PHP Processing Hook

```php
<?php
// Classes/EventListener/RteProcessingListener.php

namespace Vendor\MyExtension\EventListener;

use TYPO3\CMS\Core\Html\Event\BrokenLinkAnalysisEvent;

final class RteProcessingListener
{
    public function __invoke(BrokenLinkAnalysisEvent $event): void
    {
        // Custom link processing
        $content = $event->getContent();

        // Modify content
        $modifiedContent = $this->processContent($content);

        $event->setContent($modifiedContent);
    }

    private function processContent(string $content): string
    {
        // Custom processing logic
        return $content;
    }
}
```

## Link Browser Integration

### TYPO3 Link Handler

```yaml
# Configuration/RTE/Default.yaml
editor:
  config:
    typo3link:
      routeType: page
      additionalAttributes:
        - 'data-link-type'

    # Configure which link types are available
    typo3LinkConfig:
      allowedTypes:
        - page
        - file
        - folder
        - url
        - email
        - telephone
```

### Custom Link Handler

```php
<?php
// Classes/LinkHandler/MyLinkHandler.php

namespace Vendor\MyExtension\LinkHandler;

use TYPO3\CMS\Recordlist\LinkHandler\AbstractLinkHandler;

final class MyLinkHandler extends AbstractLinkHandler
{
    protected $linkAttributes = ['data-my-attr'];

    public function canHandleLink(array $linkParts): bool
    {
        return isset($linkParts['type']) && $linkParts['type'] === 'mylink';
    }

    public function formatCurrentUrl(): string
    {
        return 'My Link: ' . $this->linkParts['url'];
    }

    public function render(ServerRequestInterface $request): string
    {
        // Render link browser tab content
        return '<div>Custom link selection interface</div>';
    }
}
```

## Image Integration

### Image Plugin Configuration

```yaml
# Configuration/RTE/Default.yaml
editor:
  config:
    # TYPO3 image integration
    typo3image:
      routeType: image

    image:
      # Image toolbar
      toolbar:
        - imageTextAlternative
        - toggleImageCaption
        - '|'
        - imageStyle:block
        - imageStyle:side
        - '|'
        - linkImage

      # Image styles
      styles:
        options:
          - { name: 'block', title: 'Centered', icon: 'objectCenter', modelElements: ['imageBlock'] }
          - { name: 'side', title: 'Side', icon: 'objectRight', modelElements: ['imageBlock'], className: 'image-style-side' }

      # Resize options
      resizeOptions:
        - { name: 'imageResize:original', value: null, label: 'Original' }
        - { name: 'imageResize:50', value: '50', label: '50%' }
        - { name: 'imageResize:75', value: '75', label: '75%' }
```

## PageTSConfig Integration

### Per-Page Configuration

```typoscript
# Page TSConfig
RTE {
    default {
        preset = my_extension_default
    }

    # Table-specific configuration
    config.tx_news_domain_model_news {
        bodytext {
            preset = my_extension_minimal
        }
    }

    # Field-specific configuration
    config.tt_content.bodytext {
        types {
            text {
                preset = my_extension_default
            }
            textmedia {
                preset = my_extension_full
            }
        }
    }
}
```

## Debugging

### Enable Debug Mode

```php
<?php
// In AdditionalConfiguration.php
$GLOBALS['TYPO3_CONF_VARS']['BE']['debug'] = true;

// Check RTE configuration
// Access: /typo3/module/tools/configuration
// Look under: $GLOBALS['TYPO3_CONF_VARS']['RTE']
```

### JavaScript Debugging

```javascript
// In browser console
// Access CKEditor instance
const editors = CKEDITOR.instances;
console.log(editors);

// Or find by element
const editor = CKEDITOR.instances['bodytext'];
console.log(editor.config);
console.log(editor.plugins.getAll());
```

## Best Practices

### Performance

1. **Minimal Presets**: Create minimal presets for simple text fields
2. **Lazy Loading**: Use importModules only when needed
3. **Bundle Optimization**: Bundle related plugins together

### Maintainability

1. **Preset Inheritance**: Create base presets and extend them
2. **Consistent Naming**: Use clear naming for presets and plugins
3. **Documentation**: Document custom plugins and configurations

### Security

1. **Strict Processing**: Configure processing rules carefully
2. **Attribute Whitelist**: Only allow necessary attributes
3. **Content Sanitization**: Always sanitize on output
