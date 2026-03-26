---
name: mermaid
description: Create diagrams and visualizations using Mermaid syntax rendered to PNG/SVG images. Use when asked to create, draw, or visualize flowcharts, mind maps, sequence diagrams, class diagrams, ERDs, Gantt charts, state diagrams, pie charts, git graphs, or any diagram. Also use when asked to embed a chart or image in a document instead of ASCII art.
---

# Mermaid Diagram Rendering

Generate diagrams as real images (PNG/SVG) instead of ASCII art.

## Rendering

**macOS / Linux:**
```bash
bash scripts/render.sh diagram.mmd diagram.png [theme] [width]
```

**Windows (PowerShell):**
```powershell
pwsh scripts/render.ps1 diagram.mmd diagram.png [theme] [width]
```

Resolve the script path relative to this skill's directory.

Examples:
```bash
# Default (dark theme)
bash scripts/render.sh diagram.mmd diagram.png

# Light theme, wide
bash scripts/render.sh diagram.mmd diagram.png default 1600

# SVG output
bash scripts/render.sh diagram.mmd diagram.svg dark
```

The bash script auto-detects the platform and uses system Chromium on Linux ARM64 (Pi) or Puppeteer's bundled Chromium on Mac/x86/Windows.

## Workflow

1. Write Mermaid syntax to a `.mmd` file
2. Render with `scripts/render.sh` to PNG
3. Embed in target document:
   - Markdown: `![description](path/to/diagram.png)`
   - Obsidian: `![[diagram.png]]`
4. Commit both `.mmd` source and rendered image so diagrams can be updated later

## Themes

`dark` (default) | `default` (light) | `forest` (green) | `neutral` (grayscale)

## Diagram Types

### Flowchart
```
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[Other]
```

### Mind Map
```
mindmap
  root((Topic))
    Branch A
      Leaf 1
      Leaf 2
    Branch B
```

### Sequence Diagram
```
sequenceDiagram
    participant A as Service A
    participant B as Service B
    A->>B: Request
    B-->>A: Response
```

### Entity-Relationship
```
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
```

### Gantt Chart
```
gantt
    title Timeline
    dateFormat YYYY-MM-DD
    section Phase 1
    Task A :a1, 2026-01-01, 30d
    Task B :after a1, 20d
```

### Also supported
stateDiagram-v2, pie, classDiagram, gitgraph

## Tips

- `graph TD` = top-down, `graph LR` = left-right
- Wrap long text: `A["Long label"]`
- Large diagrams: pass width arg `1600` or `2000`
- Syntax check: https://mermaid.live
