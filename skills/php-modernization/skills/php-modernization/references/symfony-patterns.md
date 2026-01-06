# Modern Symfony Patterns

## Dependency Injection

### Constructor Injection (Preferred)

```php
<?php

declare(strict_types=1);

namespace App\Service;

use Psr\Log\LoggerInterface;
use Symfony\Contracts\HttpClient\HttpClientInterface;

final class PaymentService
{
    public function __construct(
        private readonly PaymentGatewayInterface $gateway,
        private readonly OrderRepository $orderRepository,
        private readonly LoggerInterface $logger,
        private readonly HttpClientInterface $httpClient,
        private readonly string $apiKey,  // Injected via services.yaml
        private readonly int $maxRetries = 3,
    ) {}

    public function processPayment(Order $order): PaymentResult
    {
        $this->logger->info('Processing payment', ['orderId' => $order->getId()]);

        return $this->gateway->charge(
            $order->getTotal(),
            $order->getCurrency()
        );
    }
}
```

### Services Configuration (PHP)

```php
<?php
// config/services.php

use App\Service\PaymentService;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return static function (ContainerConfigurator $container): void {
    $services = $container->services()
        ->defaults()
            ->autowire()
            ->autoconfigure()
            ->bind('$projectDir', '%kernel.project_dir%');

    // Auto-register services
    $services->load('App\\', '../src/')
        ->exclude('../src/{DependencyInjection,Entity,Kernel.php}');

    // Manual service configuration
    $services->set(PaymentService::class)
        ->arg('$apiKey', '%env(PAYMENT_API_KEY)%')
        ->arg('$maxRetries', '%payment.max_retries%');

    // Tagged services
    $services->set(EmailNotifier::class)
        ->tag('app.notifier', ['priority' => 100]);

    $services->set(SlackNotifier::class)
        ->tag('app.notifier', ['priority' => 50]);

    // Service alias
    $services->alias(PaymentGatewayInterface::class, StripeGateway::class);
};
```

### Service Subscribers

```php
<?php

declare(strict_types=1);

namespace App\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

final class ApiSubscriber implements EventSubscriberInterface
{
    public function __construct(
        private readonly LoggerInterface $logger,
    ) {}

    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST => ['onKernelRequest', 10],
            KernelEvents::EXCEPTION => ['onKernelException', 0],
        ];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();

        // Add request ID for tracing
        if (!$request->headers->has('X-Request-ID')) {
            $request->headers->set('X-Request-ID', uuid_create());
        }
    }

    public function onKernelException(ExceptionEvent $event): void
    {
        $this->logger->error('Unhandled exception', [
            'exception' => $event->getThrowable(),
            'request' => $event->getRequest()->getPathInfo(),
        ]);
    }
}
```

## Attribute-Based Routing

```php
<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/users', name: 'api_users_')]
final class UserController extends AbstractController
{
    public function __construct(
        private readonly UserService $userService,
    ) {}

    #[Route('', name: 'list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        $page = $request->query->getInt('page', 1);
        $limit = $request->query->getInt('limit', 20);

        return $this->json(
            $this->userService->getPaginated($page, $limit)
        );
    }

    #[Route('/{id}', name: 'show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(int $id): JsonResponse
    {
        $user = $this->userService->find($id);

        if ($user === null) {
            throw $this->createNotFoundException('User not found');
        }

        return $this->json($user);
    }

    #[Route('', name: 'create', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = $request->toArray();
        $user = $this->userService->create($data);

        return $this->json($user, Response::HTTP_CREATED);
    }

    #[Route('/{id}', name: 'update', methods: ['PUT', 'PATCH'])]
    public function update(int $id, Request $request): JsonResponse
    {
        $user = $this->userService->update($id, $request->toArray());
        return $this->json($user);
    }

    #[Route('/{id}', name: 'delete', methods: ['DELETE'])]
    public function delete(int $id): Response
    {
        $this->userService->delete($id);
        return new Response(null, Response::HTTP_NO_CONTENT);
    }
}
```

## Form Types

```php
<?php

declare(strict_types=1);

namespace App\Form;

use App\Entity\User;
use App\Enum\UserRole;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\EmailType;
use Symfony\Component\Form\Extension\Core\Type\PasswordType;
use Symfony\Component\Form\Extension\Core\Type\RepeatedType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Validator\Constraints as Assert;

final class UserType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('email', EmailType::class, [
                'label' => 'Email Address',
                'constraints' => [
                    new Assert\NotBlank(),
                    new Assert\Email(),
                ],
            ])
            ->add('name', TextType::class, [
                'label' => 'Full Name',
                'constraints' => [
                    new Assert\NotBlank(),
                    new Assert\Length(min: 2, max: 100),
                ],
            ])
            ->add('role', ChoiceType::class, [
                'choices' => UserRole::cases(),
                'choice_label' => fn(UserRole $role): string => $role->label(),
                'choice_value' => fn(?UserRole $role): string => $role?->value ?? '',
            ]);

        if ($options['include_password']) {
            $builder->add('plainPassword', RepeatedType::class, [
                'type' => PasswordType::class,
                'mapped' => false,
                'first_options' => ['label' => 'Password'],
                'second_options' => ['label' => 'Confirm Password'],
                'constraints' => [
                    new Assert\NotBlank(),
                    new Assert\Length(min: 8),
                ],
            ]);
        }
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => User::class,
            'include_password' => true,
        ]);

        $resolver->setAllowedTypes('include_password', 'bool');
    }
}
```

## Messenger (Async Processing)

### Message Definition

```php
<?php

declare(strict_types=1);

namespace App\Message;

final readonly class SendEmailMessage
{
    public function __construct(
        public string $recipient,
        public string $subject,
        public string $template,
        public array $context = [],
    ) {}
}

final readonly class ProcessOrderMessage
{
    public function __construct(
        public int $orderId,
        public bool $sendNotification = true,
    ) {}
}
```

### Message Handler

```php
<?php

declare(strict_types=1);

namespace App\MessageHandler;

use App\Message\SendEmailMessage;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;
use Symfony\Component\Mime\Email;
use Twig\Environment;

#[AsMessageHandler]
final class SendEmailMessageHandler
{
    public function __construct(
        private readonly MailerInterface $mailer,
        private readonly Environment $twig,
    ) {}

    public function __invoke(SendEmailMessage $message): void
    {
        $html = $this->twig->render($message->template, $message->context);

        $email = (new Email())
            ->to($message->recipient)
            ->subject($message->subject)
            ->html($html);

        $this->mailer->send($email);
    }
}
```

### Dispatching Messages

```php
<?php

declare(strict_types=1);

namespace App\Service;

use App\Message\SendEmailMessage;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Messenger\Stamp\DelayStamp;

final class NotificationService
{
    public function __construct(
        private readonly MessageBusInterface $bus,
    ) {}

    public function sendWelcomeEmail(User $user): void
    {
        $this->bus->dispatch(new SendEmailMessage(
            recipient: $user->getEmail(),
            subject: 'Welcome!',
            template: 'emails/welcome.html.twig',
            context: ['user' => $user],
        ));
    }

    public function sendDelayedReminder(User $user): void
    {
        // Send after 1 hour delay
        $this->bus->dispatch(
            new SendEmailMessage(
                recipient: $user->getEmail(),
                subject: 'Reminder',
                template: 'emails/reminder.html.twig',
            ),
            [new DelayStamp(3600000)]  // milliseconds
        );
    }
}
```

## Security Configuration

```php
<?php
// config/packages/security.php

use App\Entity\User;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Config\SecurityConfig;

return static function (SecurityConfig $security): void {
    $security->passwordHasher(PasswordAuthenticatedUserInterface::class)
        ->algorithm('auto');

    $security->provider('app_user_provider')
        ->entity()
            ->class(User::class)
            ->property('email');

    $security->firewall('dev')
        ->pattern('^/(_(profiler|wdt)|css|images|js)/')
        ->security(false);

    $security->firewall('main')
        ->lazy(true)
        ->provider('app_user_provider')
        ->customAuthenticators([ApiTokenAuthenticator::class])
        ->logout()
            ->path('app_logout');

    $security->accessControl()
        ->path('^/api/admin')
        ->roles(['ROLE_ADMIN']);

    $security->accessControl()
        ->path('^/api')
        ->roles(['ROLE_USER']);
};
```

## Custom Voters

```php
<?php

declare(strict_types=1);

namespace App\Security\Voter;

use App\Entity\Post;
use App\Entity\User;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;

final class PostVoter extends Voter
{
    public const VIEW = 'view';
    public const EDIT = 'edit';
    public const DELETE = 'delete';

    protected function supports(string $attribute, mixed $subject): bool
    {
        return $subject instanceof Post
            && in_array($attribute, [self::VIEW, self::EDIT, self::DELETE], true);
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token): bool
    {
        $user = $token->getUser();

        if (!$user instanceof User) {
            return false;
        }

        /** @var Post $post */
        $post = $subject;

        return match($attribute) {
            self::VIEW => $this->canView($post, $user),
            self::EDIT => $this->canEdit($post, $user),
            self::DELETE => $this->canDelete($post, $user),
            default => false,
        };
    }

    private function canView(Post $post, User $user): bool
    {
        return $post->isPublished() || $this->canEdit($post, $user);
    }

    private function canEdit(Post $post, User $user): bool
    {
        return $post->getAuthor() === $user || $user->hasRole('ROLE_EDITOR');
    }

    private function canDelete(Post $post, User $user): bool
    {
        return $post->getAuthor() === $user || $user->hasRole('ROLE_ADMIN');
    }
}
```

## Doctrine Entity Example

```php
<?php

declare(strict_types=1);

namespace App\Entity;

use App\Enum\UserRole;
use App\Repository\UserRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
#[ORM\HasLifecycleCallbacks]
class User implements UserInterface, PasswordAuthenticatedUserInterface
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 180, unique: true)]
    private string $email;

    #[ORM\Column]
    private string $password;

    #[ORM\Column(length: 100)]
    private string $name;

    #[ORM\Column(type: Types::STRING, enumType: UserRole::class)]
    private UserRole $role = UserRole::USER;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: true)]
    private ?\DateTimeImmutable $updatedAt = null;

    /** @var Collection<int, Post> */
    #[ORM\OneToMany(targetEntity: Post::class, mappedBy: 'author')]
    private Collection $posts;

    public function __construct()
    {
        $this->posts = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
    }

    #[ORM\PreUpdate]
    public function onPreUpdate(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): self
    {
        $this->email = $email;
        return $this;
    }

    public function getUserIdentifier(): string
    {
        return $this->email;
    }

    public function getRoles(): array
    {
        return [$this->role->value];
    }

    public function getPassword(): string
    {
        return $this->password;
    }

    public function setPassword(string $password): self
    {
        $this->password = $password;
        return $this;
    }

    public function eraseCredentials(): void
    {
        // Clear sensitive data if stored
    }

    /**
     * @return Collection<int, Post>
     */
    public function getPosts(): Collection
    {
        return $this->posts;
    }
}
```
