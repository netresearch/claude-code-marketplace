# CKEditor 5 Architecture

## Core Concepts

### MVC Architecture

CKEditor 5 uses a strict MVC pattern:

```
Model (Data) ←→ Controller (Commands/Observers) ←→ View (Editing/Data)
```

- **Model**: Abstract document representation
- **View**: DOM-like structure for rendering
- **Controller**: Commands and observers for state changes

### Key Components

```javascript
// Editor instance structure
editor = {
    model: Model,           // Document data model
    editing: {
        view: EditingView,  // Editable content view
        downcast: DowncastDispatcher  // Model → View
    },
    data: {
        view: DataView,     // Data processing view
        upcast: UpcastDispatcher,    // View → Model
        downcast: DowncastDispatcher // Model → View
    },
    conversion: ConversionApi,  // Unified conversion interface
    commands: CommandCollection, // Editor commands
    plugins: PluginCollection,   // Active plugins
    ui: EditorUI                 // User interface components
}
```

## Model Layer

### Schema

The schema defines what elements and attributes are allowed:

```javascript
// Schema registration
schema.register('myElement', {
    // Inheritance
    inheritAllFrom: '$block',        // Inherit from $block
    inheritTypesFrom: '$container',  // Inherit types only

    // Behavior
    isBlock: true,                   // Block element
    isObject: true,                  // Object element (atomic)
    isInline: true,                  // Inline element
    isLimit: true,                   // Cannot be split
    isSelectable: true,              // Can be selected
    isContent: true,                 // Contains content

    // Allowed contexts
    allowIn: ['$root', 'tableCell'],
    allowChildren: ['$text', 'softBreak'],

    // Attributes
    allowAttributes: ['class', 'id', 'data-*'],
    allowAttributesOf: '$block',

    // Content rules
    allowContentOf: '$block'
});

// Schema extension
schema.extend('$text', {
    allowAttributes: ['myInlineAttribute']
});

// Check schema
const isAllowed = schema.checkChild(position, 'myElement');
const canSetAttribute = schema.checkAttribute(element, 'myAttribute');
```

### Built-in Schema Items

```javascript
// Base items
'$root'          // Root element, contains blocks
'$container'     // Can contain blocks
'$block'         // Block-level element
'$blockObject'   // Block that's an atomic object
'$inlineObject'  // Inline atomic object
'$text'          // Text node
'$clipboardHolder' // Clipboard content holder

// Common elements
'paragraph'      // <p> element
'heading1-6'     // <h1>-<h6> elements
'blockQuote'     // <blockquote> element
'listItem'       // List item
'tableCell'      // Table cell
```

## Conversion System

### Upcast (View → Model)

```javascript
// Element to element
conversion.for('upcast').elementToElement({
    view: {
        name: 'div',
        classes: 'info-box'
    },
    model: 'infoBox'
});

// Element to element with attributes
conversion.for('upcast').elementToElement({
    view: {
        name: 'div',
        classes: 'info-box',
        attributes: {
            'data-type': true  // Must have this attribute
        }
    },
    model: (viewElement, { writer }) => {
        return writer.createElement('infoBox', {
            type: viewElement.getAttribute('data-type')
        });
    }
});

// Element to attribute
conversion.for('upcast').elementToAttribute({
    view: {
        name: 'span',
        classes: 'highlight'
    },
    model: {
        key: 'highlight',
        value: true
    }
});

// Attribute to attribute
conversion.for('upcast').attributeToAttribute({
    view: {
        key: 'data-align',
        value: /^(left|right|center)$/
    },
    model: {
        key: 'alignment',
        value: viewElement => viewElement.getAttribute('data-align')
    }
});
```

### Downcast (Model → View)

```javascript
// Element to element (editing view)
conversion.for('editingDowncast').elementToElement({
    model: 'infoBox',
    view: (modelElement, { writer }) => {
        return writer.createContainerElement('div', {
            class: 'info-box'
        });
    }
});

// Element to element (data view - for saving)
conversion.for('dataDowncast').elementToElement({
    model: 'infoBox',
    view: (modelElement, { writer }) => {
        return writer.createContainerElement('div', {
            class: 'info-box',
            'data-type': modelElement.getAttribute('type')
        });
    }
});

// Attribute to element
conversion.for('downcast').attributeToElement({
    model: 'highlight',
    view: (modelAttributeValue, { writer }) => {
        return writer.createAttributeElement('span', {
            class: 'highlight'
        });
    }
});

// Attribute to attribute
conversion.for('downcast').attributeToAttribute({
    model: 'alignment',
    view: modelAttributeValue => ({
        key: 'data-align',
        value: modelAttributeValue
    })
});

// Marker to element (for highlights, comments, etc.)
conversion.for('editingDowncast').markerToElement({
    model: 'comment',
    view: (markerData, { writer }) => {
        return writer.createUIElement('span', { class: 'comment-marker' });
    }
});
```

### Two-Way Conversion

```javascript
// Simplified two-way conversion
conversion.elementToElement({
    model: 'infoBox',
    view: 'div',
    converterPriority: 'high'
});

// With options
conversion.attributeToAttribute({
    model: {
        key: 'alignment',
        values: ['left', 'right', 'center']
    },
    view: {
        left: { key: 'class', value: 'align-left' },
        right: { key: 'class', value: 'align-right' },
        center: { key: 'class', value: 'align-center' }
    }
});
```

## View Layer

### View Element Types

```javascript
// Container element - can contain other elements
const container = writer.createContainerElement('div', { class: 'wrapper' });

// Attribute element - wraps text (like <strong>, <a>)
const attribute = writer.createAttributeElement('span', { class: 'highlight' });

// Empty element - self-closing (like <br>, <img>)
const empty = writer.createEmptyElement('br');

// UI element - non-editable UI
const ui = writer.createUIElement('span', { class: 'placeholder' }, function(domDocument) {
    const domElement = this.toDomElement(domDocument);
    domElement.textContent = 'Click to edit';
    return domElement;
});

// Editable element - nested editable area
const editable = writer.createEditableElement('div', { class: 'editable-area' });
```

### View Attributes

```javascript
// Setting attributes
writer.setAttribute('class', 'my-class', viewElement);
writer.setAttribute('data-id', '123', viewElement);

// Adding/removing classes
writer.addClass('active', viewElement);
writer.removeClass('inactive', viewElement);

// Setting styles
writer.setStyle('color', 'red', viewElement);
writer.setStyle({
    'background-color': 'yellow',
    'font-weight': 'bold'
}, viewElement);
```

## Command Pattern

### Basic Command

```javascript
import { Command } from '@ckeditor/ckeditor5-core';

export default class InsertInfoBoxCommand extends Command {
    execute(options = {}) {
        const editor = this.editor;
        const model = editor.model;
        const selection = model.document.selection;

        model.change(writer => {
            const infoBox = writer.createElement('infoBox', {
                type: options.type || 'info'
            });

            // Insert at selection
            model.insertObject(infoBox, selection, null, {
                setSelection: 'on',
                findOptimalPosition: 'auto'
            });
        });
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;

        // Check if command can be executed
        const allowedIn = model.schema.findAllowedParent(
            selection.getFirstPosition(),
            'infoBox'
        );

        this.isEnabled = allowedIn !== null;

        // Update command value based on selection
        const selectedElement = selection.getSelectedElement();
        if (selectedElement && selectedElement.is('element', 'infoBox')) {
            this.value = selectedElement.getAttribute('type');
        } else {
            this.value = null;
        }
    }
}
```

### Command Registration

```javascript
// In plugin init()
init() {
    const editor = this.editor;

    editor.commands.add('insertInfoBox', new InsertInfoBoxCommand(editor));

    // Execute command
    editor.execute('insertInfoBox', { type: 'warning' });

    // Check command state
    const command = editor.commands.get('insertInfoBox');
    console.log(command.isEnabled);
    console.log(command.value);
}
```

## Plugin Architecture

### Plugin Dependencies

```javascript
import { Plugin } from '@ckeditor/ckeditor5-core';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';

export default class MyPlugin extends Plugin {
    // Required plugins
    static get requires() {
        return [Widget, 'Paragraph'];  // Can mix classes and names
    }

    // Plugin name for dependency resolution
    static get pluginName() {
        return 'MyPlugin';
    }

    // Lifecycle methods
    init() {
        // Called after all dependencies are initialized
    }

    afterInit() {
        // Called after all plugins are initialized
    }

    destroy() {
        // Cleanup
        super.destroy();
    }
}
```

### Plugin Communication

```javascript
// Access other plugins
init() {
    const imagePlugin = this.editor.plugins.get('ImageUpload');

    // Listen to events
    this.listenTo(imagePlugin, 'uploadComplete', (evt, data) => {
        console.log('Image uploaded:', data.url);
    });
}

// Fire events
this.fire('myEvent', { data: 'value' });

// Decorate methods
decorate('execute');  // Allows listening to method calls
```

## Event System

### Event Types

```javascript
// Model events
editor.model.document.on('change:data', (evt, batch) => {
    console.log('Document changed');
});

// Selection events
editor.model.document.selection.on('change:range', () => {
    console.log('Selection changed');
});

// View events
editor.editing.view.document.on('keydown', (evt, data) => {
    if (data.keyCode === 13) {  // Enter key
        console.log('Enter pressed');
    }
});

// Focus events
editor.editing.view.document.on('focus', () => {
    console.log('Editor focused');
});

// Clipboard events
editor.editing.view.document.on('clipboardInput', (evt, data) => {
    console.log('Paste event');
});
```

### Event Priorities

```javascript
// Priority levels (higher = executed first)
editor.model.document.on('change:data', callback, { priority: 'highest' }); // 100000
editor.model.document.on('change:data', callback, { priority: 'high' });    // 1000
editor.model.document.on('change:data', callback, { priority: 'normal' });  // 0
editor.model.document.on('change:data', callback, { priority: 'low' });     // -1000
editor.model.document.on('change:data', callback, { priority: 'lowest' });  // -100000

// Stop event propagation
editor.model.document.on('change:data', (evt) => {
    evt.stop();  // Stop propagation
    evt.return = 'custom value';  // Return value
});
```

## Widget System

### Creating Widgets

```javascript
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget';

// In downcast converter
conversion.for('editingDowncast').elementToElement({
    model: 'infoBox',
    view: (modelElement, { writer }) => {
        const container = writer.createContainerElement('div', {
            class: 'info-box'
        });

        // Make it a widget (selectable, with toolbar)
        return toWidget(container, writer, {
            label: 'Info box widget',
            hasSelectionHandle: true
        });
    }
});

// Nested editable
conversion.for('editingDowncast').elementToElement({
    model: 'infoBoxContent',
    view: (modelElement, { writer }) => {
        const editable = writer.createEditableElement('div', {
            class: 'info-box-content'
        });

        return toWidgetEditable(editable, writer);
    }
});
```

### Widget Utils

```javascript
import { isWidget, getSelectedWidgetModel } from '@ckeditor/ckeditor5-widget';

// Check if element is widget
if (isWidget(viewElement)) {
    // Handle widget
}

// Get selected widget
const widget = getSelectedWidgetModel(selection);
```

## Data Pipeline

### Getting/Setting Data

```javascript
// Get editor data (HTML)
const htmlData = editor.getData();

// Set editor data
editor.setData('<p>New content</p>');

// Get model data (for debugging)
const modelData = editor.model.document.getRoot();

// Get view data
const viewData = editor.data.toView(modelData);
```

### Custom Data Processors

```javascript
import { DataProcessor } from '@ckeditor/ckeditor5-engine';

class MarkdownDataProcessor {
    toView(data) {
        // Convert Markdown to view
        return markdown.toHTML(data);
    }

    toData(viewFragment) {
        // Convert view to Markdown
        return html.toMarkdown(viewFragment);
    }
}

// Register
editor.data.processor = new MarkdownDataProcessor();
```

## Best Practices

### Performance

```javascript
// Batch model changes
model.change(writer => {
    // Multiple operations in single change block
    const element1 = writer.createElement('paragraph');
    const element2 = writer.createElement('paragraph');
    writer.insert(element1, position1);
    writer.insert(element2, position2);
});

// Use enqueueChange for deferred operations
model.enqueueChange({ isUndoable: false }, writer => {
    // Changes that shouldn't be in undo stack
});
```

### Memory Management

```javascript
// Clean up listeners in destroy()
destroy() {
    this.stopListening();  // Remove all listeners
    super.destroy();
}

// Use WeakMap for element references
const elementMap = new WeakMap();
```

### Debugging

```javascript
// Enable debug mode
import CKEditorInspector from '@ckeditor/ckeditor5-inspector';
CKEditorInspector.attach(editor);

// Log model structure
console.log(editor.model.document.getRoot().toJSON());

// Log view structure
console.log(editor.editing.view.document.getRoot());
```
