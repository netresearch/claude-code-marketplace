# Signal Patterns Reference

Detailed patterns for detecting friction signals in user messages and tool outputs.

## User Correction Patterns

### Direct Negation
```regex
\bno\b              # Simple "no"
\bstop\b            # Stop doing something
\bdon'?t\b          # Don't / dont
\bnot\s+that\b      # Not that
\bwrong\b           # Wrong approach
```

### Reference to Prior Instruction
```regex
i\s+said            # "I said..."
you\s+didn'?t       # "You didn't..."
i\s+told\s+you      # "I told you..."
i\s+asked           # "I asked..."
that'?s\s+not\s+what # "That's not what..."
```

### Questioning Claude's Action
```regex
why\s+did\s+you     # "Why did you..."
what\s+are\s+you    # "What are you..."
you\s+should\s+have # "You should have..."
```

### Explicit Correction
```regex
incorrect           # "incorrect"
that'?s\s+wrong     # "that's wrong"
fix\s+that          # "fix that"
undo\s+that         # "undo that"
revert              # "revert"
```

## Tone Escalation Patterns

### Capitalization
```regex
[A-Z]{3,}           # 3+ consecutive uppercase letters
                    # e.g., "DON'T", "STOP", "NO"
```

### Punctuation Emphasis
```regex
!{2,}               # Multiple exclamation marks
\?{2,}              # Multiple question marks
```

### Repetition Keywords
```regex
\bagain\b           # "again"
for\s+the\s+last\s+time  # "for the last time"
how\s+many\s+times  # "how many times"
i\s+already\s+said  # "I already said"
```

### Frustration Indicators
```regex
seriously           # "seriously"
come\s+on           # "come on"
please\s+just       # "please just"
```

## Command Failure Patterns (stderr)

### File/Path Errors
```regex
ENOENT              # File/directory not found
EACCES              # Permission denied
EEXIST              # File already exists
EISDIR              # Is a directory
ENOTDIR             # Not a directory
```

### Network Errors
```regex
ECONNREFUSED        # Connection refused
ETIMEDOUT           # Connection timed out
ENOTFOUND           # DNS lookup failed
EHOSTUNREACH        # Host unreachable
```

### Command Errors
```regex
command\s+not\s+found     # Command not found
permission\s+denied       # Permission denied
no\s+such\s+file         # No such file
syntax\s+error           # Syntax error
```

### HTTP Status Codes
```regex
\b401\b             # Unauthorized
\b403\b             # Forbidden
\b404\b             # Not found
\b500\b             # Server error
\b502\b             # Bad gateway
\b503\b             # Service unavailable
```

### Package Manager Errors
```regex
ERESOLVE            # npm dependency resolution
ERR_PNPM            # pnpm errors
ModuleNotFoundError # Python import error
ImportError         # Python import error
```

## Repetition Detection

### Similarity Threshold
- Jaccard similarity > 0.5 indicates similar instruction
- Check last 10 user messages
- Minimum 2 similar messages to trigger

### Keyword Extraction
1. Tokenize message into words
2. Remove stopwords
3. Compare remaining keywords
4. Calculate overlap ratio

## Priority Weighting

| Signal Type | Priority | Min Confidence |
|-------------|----------|----------------|
| COMMAND_FAILURE | 100 | 0.85 |
| USER_CORRECTION | 80 | 0.50 |
| REPETITION | 60 | 0.40 |
| TONE_ESCALATION | 40 | 0.20 |

## Evidence Requirements

| Signal Type | Min Evidence | Notes |
|-------------|--------------|-------|
| COMMAND_FAILURE | 1 | Single failure is high-signal |
| USER_CORRECTION | 2 | Need pattern, not one-off |
| REPETITION | 3 | Need clear repetition pattern |
| TONE_ESCALATION | N/A | Triggers review only |
