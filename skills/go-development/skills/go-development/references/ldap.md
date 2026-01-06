# LDAP/Active Directory Integration in Go

## Client Setup

### Basic LDAP Client

```go
package ldap

import (
    "crypto/tls"
    "fmt"

    "github.com/go-ldap/ldap/v3"
)

type Client struct {
    conn       *ldap.Conn
    baseDN     string
    bindDN     string
    bindPW     string
    userFilter string
}

type Config struct {
    Host       string
    Port       int
    BaseDN     string
    BindDN     string
    BindPW     string
    UseTLS     bool
    SkipVerify bool
}

func NewClient(cfg Config) (*Client, error) {
    address := fmt.Sprintf("%s:%d", cfg.Host, cfg.Port)

    var conn *ldap.Conn
    var err error

    if cfg.UseTLS {
        tlsConfig := &tls.Config{
            InsecureSkipVerify: cfg.SkipVerify,
            ServerName:         cfg.Host,
        }
        conn, err = ldap.DialTLS("tcp", address, tlsConfig)
    } else {
        conn, err = ldap.Dial("tcp", address)
    }

    if err != nil {
        return nil, fmt.Errorf("failed to connect to LDAP: %w", err)
    }

    // Bind with credentials
    if err := conn.Bind(cfg.BindDN, cfg.BindPW); err != nil {
        conn.Close()
        return nil, fmt.Errorf("failed to bind: %w", err)
    }

    return &Client{
        conn:   conn,
        baseDN: cfg.BaseDN,
        bindDN: cfg.BindDN,
        bindPW: cfg.BindPW,
    }, nil
}

func (c *Client) Close() error {
    if c.conn != nil {
        c.conn.Close()
    }
    return nil
}
```

### Connection Pool

```go
type ClientPool struct {
    cfg     Config
    pool    chan *Client
    maxSize int
}

func NewClientPool(cfg Config, maxSize int) *ClientPool {
    return &ClientPool{
        cfg:     cfg,
        pool:    make(chan *Client, maxSize),
        maxSize: maxSize,
    }
}

func (p *ClientPool) Get() (*Client, error) {
    select {
    case client := <-p.pool:
        // Test connection
        if err := client.conn.Bind(p.cfg.BindDN, p.cfg.BindPW); err == nil {
            return client, nil
        }
        // Connection dead, create new
        client.Close()
    default:
        // Pool empty
    }

    return NewClient(p.cfg)
}

func (p *ClientPool) Put(client *Client) {
    select {
    case p.pool <- client:
        // Returned to pool
    default:
        // Pool full, close connection
        client.Close()
    }
}
```

## User Operations

### User Model

```go
type User struct {
    DN                string
    CN                string
    SAMAccountName    string
    UserPrincipalName string
    Email             string
    DisplayName       string
    FirstName         string
    LastName          string
    Department        string
    Title             string
    Manager           string
    MemberOf          []string
    Enabled           bool
    LastLogon         time.Time
}

func userFromEntry(entry *ldap.Entry) *User {
    user := &User{
        DN:                entry.DN,
        CN:                entry.GetAttributeValue("cn"),
        SAMAccountName:    entry.GetAttributeValue("sAMAccountName"),
        UserPrincipalName: entry.GetAttributeValue("userPrincipalName"),
        Email:             entry.GetAttributeValue("mail"),
        DisplayName:       entry.GetAttributeValue("displayName"),
        FirstName:         entry.GetAttributeValue("givenName"),
        LastName:          entry.GetAttributeValue("sn"),
        Department:        entry.GetAttributeValue("department"),
        Title:             entry.GetAttributeValue("title"),
        Manager:           entry.GetAttributeValue("manager"),
        MemberOf:          entry.GetAttributeValues("memberOf"),
    }

    // Parse userAccountControl for enabled status
    uac := entry.GetAttributeValue("userAccountControl")
    if uac != "" {
        uacInt, _ := strconv.Atoi(uac)
        user.Enabled = (uacInt & 0x2) == 0 // ACCOUNTDISABLE flag
    }

    return user
}
```

### Find Users

```go
var userAttributes = []string{
    "dn", "cn", "sAMAccountName", "userPrincipalName",
    "mail", "displayName", "givenName", "sn",
    "department", "title", "manager", "memberOf",
    "userAccountControl",
}

func (c *Client) FindUserBySAM(samAccountName string) (*User, error) {
    filter := fmt.Sprintf("(&(objectClass=user)(sAMAccountName=%s))",
        ldap.EscapeFilter(samAccountName))

    return c.findUser(filter)
}

func (c *Client) FindUserByEmail(email string) (*User, error) {
    filter := fmt.Sprintf("(&(objectClass=user)(mail=%s))",
        ldap.EscapeFilter(email))

    return c.findUser(filter)
}

func (c *Client) FindUserByDN(dn string) (*User, error) {
    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     dn,
        Scope:      ldap.ScopeBaseObject,
        Filter:     "(objectClass=user)",
        Attributes: userAttributes,
    })
    if err != nil {
        return nil, err
    }

    if len(result.Entries) == 0 {
        return nil, ErrUserNotFound
    }

    return userFromEntry(result.Entries[0]), nil
}

func (c *Client) findUser(filter string) (*User, error) {
    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeWholeSubtree,
        Filter:     filter,
        Attributes: userAttributes,
    })
    if err != nil {
        return nil, fmt.Errorf("search failed: %w", err)
    }

    if len(result.Entries) == 0 {
        return nil, ErrUserNotFound
    }

    return userFromEntry(result.Entries[0]), nil
}

func (c *Client) ListUsers(filter string, limit int) ([]*User, error) {
    if filter == "" {
        filter = "(objectClass=user)"
    }

    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeWholeSubtree,
        Filter:     filter,
        Attributes: userAttributes,
        SizeLimit:  limit,
    })
    if err != nil {
        return nil, err
    }

    users := make([]*User, 0, len(result.Entries))
    for _, entry := range result.Entries {
        users = append(users, userFromEntry(entry))
    }

    return users, nil
}
```

## Authentication

### Validate Credentials

```go
func (c *Client) Authenticate(username, password string) (*User, error) {
    // First, find the user
    user, err := c.FindUserBySAM(username)
    if err != nil {
        return nil, fmt.Errorf("user not found: %w", err)
    }

    // Try to bind with user's credentials
    err = c.conn.Bind(user.DN, password)
    if err != nil {
        // Re-bind as service account
        c.conn.Bind(c.bindDN, c.bindPW)
        return nil, ErrInvalidCredentials
    }

    // Re-bind as service account for subsequent operations
    c.conn.Bind(c.bindDN, c.bindPW)

    return user, nil
}

// Alternative: Create new connection for auth
func (c *Client) AuthenticateWithNewConn(username, password string) (*User, error) {
    user, err := c.FindUserBySAM(username)
    if err != nil {
        return nil, err
    }

    // Create separate connection for auth
    cfg := Config{
        Host:   c.cfg.Host,
        Port:   c.cfg.Port,
        BaseDN: c.baseDN,
        BindDN: user.DN,
        BindPW: password,
        UseTLS: c.cfg.UseTLS,
    }

    authClient, err := NewClient(cfg)
    if err != nil {
        return nil, ErrInvalidCredentials
    }
    authClient.Close()

    return user, nil
}
```

## Password Operations

### Change Password

```go
func (c *Client) ChangePassword(userDN, oldPassword, newPassword string) error {
    // AD requires the password in a specific format
    oldPwdEncoded := encodePassword(oldPassword)
    newPwdEncoded := encodePassword(newPassword)

    modifyRequest := ldap.NewModifyRequest(userDN, nil)
    modifyRequest.Delete("unicodePwd", []string{oldPwdEncoded})
    modifyRequest.Add("unicodePwd", []string{newPwdEncoded})

    return c.conn.Modify(modifyRequest)
}

func (c *Client) ResetPassword(userDN, newPassword string) error {
    // Admin reset - doesn't require old password
    newPwdEncoded := encodePassword(newPassword)

    modifyRequest := ldap.NewModifyRequest(userDN, nil)
    modifyRequest.Replace("unicodePwd", []string{newPwdEncoded})

    return c.conn.Modify(modifyRequest)
}

func encodePassword(password string) string {
    // AD requires UTF-16LE encoded password surrounded by quotes
    utf16 := utf16.Encode([]rune("\"" + password + "\""))
    pwBytes := make([]byte, len(utf16)*2)
    for i, v := range utf16 {
        pwBytes[i*2] = byte(v)
        pwBytes[i*2+1] = byte(v >> 8)
    }
    return string(pwBytes)
}
```

## Group Operations

### Group Model

```go
type Group struct {
    DN          string
    CN          string
    Description string
    Members     []string
    MemberOf    []string
}

func (c *Client) FindGroup(cn string) (*Group, error) {
    filter := fmt.Sprintf("(&(objectClass=group)(cn=%s))", ldap.EscapeFilter(cn))

    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeWholeSubtree,
        Filter:     filter,
        Attributes: []string{"dn", "cn", "description", "member", "memberOf"},
    })
    if err != nil {
        return nil, err
    }

    if len(result.Entries) == 0 {
        return nil, ErrGroupNotFound
    }

    entry := result.Entries[0]
    return &Group{
        DN:          entry.DN,
        CN:          entry.GetAttributeValue("cn"),
        Description: entry.GetAttributeValue("description"),
        Members:     entry.GetAttributeValues("member"),
        MemberOf:    entry.GetAttributeValues("memberOf"),
    }, nil
}

func (c *Client) AddUserToGroup(userDN, groupDN string) error {
    modifyRequest := ldap.NewModifyRequest(groupDN, nil)
    modifyRequest.Add("member", []string{userDN})
    return c.conn.Modify(modifyRequest)
}

func (c *Client) RemoveUserFromGroup(userDN, groupDN string) error {
    modifyRequest := ldap.NewModifyRequest(groupDN, nil)
    modifyRequest.Delete("member", []string{userDN})
    return c.conn.Modify(modifyRequest)
}

func (c *Client) IsUserInGroup(userDN, groupCN string) (bool, error) {
    user, err := c.FindUserByDN(userDN)
    if err != nil {
        return false, err
    }

    for _, groupDN := range user.MemberOf {
        if strings.Contains(strings.ToLower(groupDN), strings.ToLower("CN="+groupCN)) {
            return true, nil
        }
    }

    return false, nil
}
```

## Error Handling

```go
var (
    ErrUserNotFound       = errors.New("user not found")
    ErrGroupNotFound      = errors.New("group not found")
    ErrInvalidCredentials = errors.New("invalid credentials")
    ErrConnectionFailed   = errors.New("LDAP connection failed")
    ErrPermissionDenied   = errors.New("permission denied")
)

func translateLDAPError(err error) error {
    if ldapErr, ok := err.(*ldap.Error); ok {
        switch ldapErr.ResultCode {
        case ldap.LDAPResultNoSuchObject:
            return ErrUserNotFound
        case ldap.LDAPResultInvalidCredentials:
            return ErrInvalidCredentials
        case ldap.LDAPResultInsufficientAccessRights:
            return ErrPermissionDenied
        }
    }
    return err
}
```

## Computer Objects

```go
type Computer struct {
    DN             string
    CN             string
    DNSHostName    string
    OperatingSystem string
    OSVersion      string
    LastLogon      time.Time
    Enabled        bool
}

func (c *Client) ListComputers(filter string) ([]*Computer, error) {
    if filter == "" {
        filter = "(objectClass=computer)"
    }

    result, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeWholeSubtree,
        Filter:     filter,
        Attributes: []string{
            "dn", "cn", "dNSHostName",
            "operatingSystem", "operatingSystemVersion",
            "lastLogonTimestamp", "userAccountControl",
        },
    })
    if err != nil {
        return nil, err
    }

    computers := make([]*Computer, 0, len(result.Entries))
    for _, entry := range result.Entries {
        computers = append(computers, &Computer{
            DN:              entry.DN,
            CN:              entry.GetAttributeValue("cn"),
            DNSHostName:     entry.GetAttributeValue("dNSHostName"),
            OperatingSystem: entry.GetAttributeValue("operatingSystem"),
            OSVersion:       entry.GetAttributeValue("operatingSystemVersion"),
        })
    }

    return computers, nil
}

## Testing LDAP with Testcontainers

### LDAP Lazy Binding Behavior

**Critical**: LDAP connections use **lazy binding**. The `Dial()` or `DialTLS()` call only establishes a TCP connection - authentication is not validated until the first LDAP operation.

```go
// Connection succeeds even with invalid credentials!
conn, err := ldap.Dial("tcp", "ldap.example.com:389")
if err != nil {
    // Only fails on network/DNS errors, NOT auth errors
}

// Auth is validated HERE, on first operation
err = conn.Bind("cn=admin,dc=example,dc=com", "wrong-password")
// NOW you get auth errors
```

### OpenLDAP Anonymous Reads

OpenLDAP allows anonymous read access by default. This affects health checks:

```go
// Health check using Search works WITHOUT authentication
func (c *Client) HealthCheck() error {
    _, err := c.conn.Search(&ldap.SearchRequest{
        BaseDN:     c.baseDN,
        Scope:      ldap.ScopeBaseObject,
        Filter:     "(objectClass=*)",
        Attributes: []string{"1.1"}, // Request no attributes
        SizeLimit:  1,
    })
    return err  // Works even without Bind!
}

// For true auth validation, use Bind explicitly
func (c *Client) ValidateCredentials() error {
    return c.conn.Bind(c.bindDN, c.bindPassword)
}
```

### Testcontainers Pattern for LDAP

Use ephemeral OpenLDAP containers for integration tests:

```go
//go:build integration

package ldap_test

import (
    "context"
    "testing"

    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/wait"
)

func setupOpenLDAPContainer(t *testing.T) (host string, port int, cleanup func()) {
    ctx := context.Background()

    req := testcontainers.ContainerRequest{
        Image:        "osixia/openldap:1.5.0",  // Pin version!
        ExposedPorts: []string{"389/tcp"},
        Env: map[string]string{
            "LDAP_ORGANISATION":    "Test Org",
            "LDAP_DOMAIN":          "example.com",
            "LDAP_ADMIN_PASSWORD":  "admin",  // OK for ephemeral test container
            "LDAP_BASE_DN":         "dc=example,dc=com",
        },
        WaitingFor: wait.ForListeningPort("389/tcp"),
    }

    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    if err != nil {
        t.Fatalf("Failed to start container: %v", err)
    }

    mappedPort, _ := container.MappedPort(ctx, "389")
    hostIP, _ := container.Host(ctx)

    return hostIP, mappedPort.Int(), func() {
        container.Terminate(ctx)
    }
}

func TestLDAPIntegration(t *testing.T) {
    host, port, cleanup := setupOpenLDAPContainer(t)
    defer cleanup()

    client, err := NewClient(Config{
        Host:   host,
        Port:   port,
        BindDN: "cn=admin,dc=example,dc=com",
        BindPW: "admin",
        BaseDN: "dc=example,dc=com",
    })
    require.NoError(t, err)
    defer client.Close()

    // Test operations...
}
```

### Security Note: Test Credentials

Hardcoded credentials in testcontainer setup are acceptable because:
1. Containers are ephemeral (destroyed after test)
2. Run on isolated localhost ports
3. Contain no real data

**Never** use production credentials in tests. Always use dedicated test accounts with minimal permissions.
