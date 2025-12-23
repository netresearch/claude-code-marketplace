---
name: typo3-ckeditor5
description: "Agent Skill: CKEditor 5 development patterns for TYPO3 v12+. This skill should be used when developing custom CKEditor 5 plugins for TYPO3, configuring RTE presets, integrating CKEditor with TYPO3 backend modules, or migrating from CKEditor 4. Covers plugin architecture (schema, conversion, commands), TYPO3 YAML configuration, ES6 module development, and complete migration guides. By Netresearch."
---

# TYPO3 CKEditor 5 Skill

Expert patterns for CKEditor 5 integration in TYPO3, including custom plugin development, configuration, and migration from CKEditor 4.

## Expertise Areas

### CKEditor 5 Architecture
- Plugin system and architecture
- Schema and conversion system
- Command pattern implementation
- UI component development

### TYPO3 Integration
- RTE configuration (YAML)
- Custom plugin registration
- Content element integration
- Backend module integration

### Migration Patterns
- CKEditor 4 to 5 migration
- Custom plugin conversion
- Configuration transformation
- Data migration strategies

## Reference Files

- `references/ckeditor5-architecture.md` - CKEditor 5 core concepts
- `references/typo3-integration.md` - TYPO3-specific integration patterns
- `references/plugin-development.md` - Custom plugin creation guide
- `references/migration-guide.md` - CKEditor 4 to 5 migration

## Core Patterns

### CKEditor 5 Plugin Structure

```javascript
// packages/my-plugin/src/myplugin.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import MyPluginEditing from './mypluginediting';
import MyPluginUI from './mypluginui';

export default class MyPlugin extends Plugin {
    static get requires() {
        return [MyPluginEditing, MyPluginUI];
    }

    static get pluginName() {
        return 'MyPlugin';
    }
}
```

### Editing Plugin with Schema

```javascript
// packages/my-plugin/src/mypluginediting.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import MyPluginCommand from './myplugincommand';

export default class MyPluginEditing extends Plugin {
    static get pluginName() {
        return 'MyPluginEditing';
    }

    init() {
        this._defineSchema();
        this._defineConverters();
        this._defineCommands();
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register('myElement', {
            inheritAllFrom: '$blockObject',
            allowAttributes: ['myAttribute']
        });

        schema.extend('$text', {
            allowAttributes: ['myInlineAttribute']
        });
    }

    _defineConverters() {
        const conversion = this.editor.conversion;

        // Upcast (view -> model)
        conversion.for('upcast').elementToElement({
            view: {
                name: 'div',
                classes: 'my-element'
            },
            model: (viewElement, { writer }) => {
                return writer.createElement('myElement', {
                    myAttribute: viewElement.getAttribute('data-my-attr')
                });
            }
        });

        // Downcast (model -> view)
        conversion.for('downcast').elementToElement({
            model: 'myElement',
            view: (modelElement, { writer }) => {
                return writer.createContainerElement('div', {
                    class: 'my-element',
                    'data-my-attr': modelElement.getAttribute('myAttribute')
                });
            }
        });
    }

    _defineCommands() {
        const editor = this.editor;
        editor.commands.add('myCommand', new MyPluginCommand(editor));
    }
}
```

### TYPO3 RTE Configuration (YAML)

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
        - link
        - '|'
        - bulletedList
        - numberedList
        - '|'
        - blockQuote
        - insertTable
        - '|'
        - myPlugin  # Custom plugin
        - '|'
        - undo
        - redo

    # Heading configuration
    heading:
      options:
        - { model: 'paragraph', title: 'Paragraph', class: 'ck-heading_paragraph' }
        - { model: 'heading2', view: 'h2', title: 'Heading 2', class: 'ck-heading_heading2' }
        - { model: 'heading3', view: 'h3', title: 'Heading 3', class: 'ck-heading_heading3' }

    # Table configuration
    table:
      contentToolbar:
        - tableColumn
        - tableRow
        - mergeTableCells

    # Link configuration
    link:
      decorators:
        openInNewTab:
          mode: manual
          label: 'Open in new tab'
          attributes:
            target: '_blank'
            rel: 'noopener noreferrer'

    # Import custom modules
    importModules:
      - '@typo3/rte-ckeditor/plugin/typo3-link.js'
      - '@vendor/my-extension/plugin/my-plugin.js'

# Processing configuration
processing:
  allowTags:
    - a
    - abbr
    - b
    - blockquote
    - br
    - code
    - div
    - em
    - h2
    - h3
    - h4
    - hr
    - i
    - img
    - li
    - ol
    - p
    - pre
    - span
    - strong
    - sub
    - sup
    - table
    - tbody
    - td
    - th
    - thead
    - tr
    - u
    - ul
```

### Custom Plugin Registration in TYPO3

```php
<?php
// ext_localconf.php

// Register custom CKEditor 5 plugin
$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['my_preset'] = 'EXT:my_extension/Configuration/RTE/MyPreset.yaml';

// Make plugin available
$GLOBALS['TYPO3_CONF_VARS']['SYS']['ckeditor5']['plugins']['my-plugin'] = [
    'entryPoint' => 'EXT:my_extension/Resources/Public/JavaScript/Ckeditor/my-plugin.js',
    'stylesheets' => [
        'EXT:my_extension/Resources/Public/Css/Ckeditor/my-plugin.css',
    ],
];
```

### Command Pattern

```javascript
// packages/my-plugin/src/myplugincommand.js
import { Command } from '@ckeditor/ckeditor5-core';

export default class MyPluginCommand extends Command {
    execute(options = {}) {
        const editor = this.editor;
        const model = editor.model;

        model.change(writer => {
            const element = writer.createElement('myElement', {
                myAttribute: options.value || 'default'
            });

            model.insertContent(element);
            writer.setSelection(element, 'on');
        });
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent(
            selection.getFirstPosition(),
            'myElement'
        );

        this.isEnabled = allowedIn !== null;
    }
}
```

### UI Plugin with Dropdown

```javascript
// packages/my-plugin/src/mypluginui.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import { ButtonView, createDropdown, addListToDropdown } from '@ckeditor/ckeditor5-ui';
import { Collection } from '@ckeditor/ckeditor5-utils';

export default class MyPluginUI extends Plugin {
    static get pluginName() {
        return 'MyPluginUI';
    }

    init() {
        const editor = this.editor;

        editor.ui.componentFactory.add('myPlugin', locale => {
            const dropdownView = createDropdown(locale);
            const items = new Collection();

            items.add({
                type: 'button',
                model: {
                    withText: true,
                    label: 'Option 1',
                    value: 'option1'
                }
            });

            items.add({
                type: 'button',
                model: {
                    withText: true,
                    label: 'Option 2',
                    value: 'option2'
                }
            });

            addListToDropdown(dropdownView, items);

            dropdownView.buttonView.set({
                label: 'My Plugin',
                tooltip: true,
                withText: true
            });

            dropdownView.on('execute', evt => {
                editor.execute('myCommand', { value: evt.source.value });
                editor.editing.view.focus();
            });

            return dropdownView;
        });
    }
}
```

## Migration Checklist

### CKEditor 4 to 5 Migration
- [ ] Audit existing CKEditor 4 plugins
- [ ] Map CKEditor 4 features to CKEditor 5 equivalents
- [ ] Convert custom plugins to CKEditor 5 architecture
- [ ] Update YAML configuration from PageTSConfig
- [ ] Test content rendering in frontend
- [ ] Verify existing content compatibility
- [ ] Update TCA configurations
- [ ] Test all content element types

### Plugin Conversion
- [ ] Convert plugin.js to class-based architecture
- [ ] Implement schema definitions
- [ ] Create upcast/downcast converters
- [ ] Implement command pattern
- [ ] Create UI components
- [ ] Add TypeScript declarations (optional)
- [ ] Write unit tests
- [ ] Document plugin API

## Verification

Run the verification script:

```bash
./scripts/verify-ckeditor5.sh /path/to/extension
```

## Related Skills

- **typo3-extension-upgrade-skill**: References this skill for RTE migration
- **php-modernization-skill**: Modern PHP patterns for backend integration
