## {{TITLE}}

**Trigger**: {{TRIGGER}}

**Action**: {{ACTION}}

{{#if EVIDENCE}}
**Evidence**:
{{#each EVIDENCE}}
- {{this.quote}} ({{this.timestamp}})
{{/each}}
{{/if}}
