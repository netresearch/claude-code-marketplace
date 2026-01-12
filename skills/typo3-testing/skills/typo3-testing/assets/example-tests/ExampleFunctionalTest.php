<?php

declare(strict_types=1);

namespace Vendor\Extension\Tests\Functional\Domain\Repository;

use TYPO3\TestingFramework\Core\Functional\FunctionalTestCase;
use Vendor\Extension\Domain\Model\Product;
use Vendor\Extension\Domain\Repository\ProductRepository;

/**
 * Example functional test demonstrating TYPO3 testing patterns
 *
 * Functional tests use a real database and full TYPO3 instance.
 * They test repositories, controllers, and integration scenarios.
 */
final class ProductRepositoryTest extends FunctionalTestCase
{
    protected ProductRepository $subject;

    /**
     * Extensions to load for this test
     */
    protected array $testExtensionsToLoad = [
        'typo3conf/ext/my_extension',
    ];

    protected function setUp(): void
    {
        parent::setUp();

        // Get repository from dependency injection container
        $this->subject = $this->get(ProductRepository::class);
    }

    /**
     * @test
     */
    public function findsProductsByCategory(): void
    {
        // Import test data from CSV fixture
        $this->importCSVDataSet(__DIR__ . '/../Fixtures/Products.csv');

        // Execute repository method
        $products = $this->subject->findByCategory(1);

        // Assert results
        self::assertCount(3, $products);
        self::assertInstanceOf(Product::class, $products[0]);
    }

    /**
     * @test
     */
    public function findsVisibleProductsOnly(): void
    {
        $this->importCSVDataSet(__DIR__ . '/../Fixtures/ProductsWithHidden.csv');

        $products = $this->subject->findAll();

        // Only visible products should be returned
        self::assertCount(2, $products);

        foreach ($products as $product) {
            self::assertFalse($product->isHidden());
        }
    }

    /**
     * @test
     */
    public function persistsNewProduct(): void
    {
        $this->importCSVDataSet(__DIR__ . '/../Fixtures/Pages.csv');

        $product = new Product();
        $product->setTitle('New Product');
        $product->setPrice(19.99);
        $product->setPid(1);

        $this->subject->add($product);

        // Persist to database
        $this->persistenceManager->persistAll();

        // Verify product was saved
        $savedProducts = $this->subject->findAll();
        self::assertCount(1, $savedProducts);
        self::assertSame('New Product', $savedProducts[0]->getTitle());
    }
}
