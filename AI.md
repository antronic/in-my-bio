# AI Agent Context

## Project Overview
- **Name**: in-my-bio
- **Type**:Astro static website
- **Framework**: Astro 5.x with TypeScript
- **Package Manager**: Bun

## Project Structure
```
/Users/Shared/dev/wwwj/projects/in-my-bio/
├── src/
│   ├── components/   # Astro components (.astro files)
│   ├── layouts/      # Page layouts
│   └── pages/        # Route pages (index.astro)
├── public/           # Static assets
├── astro.config.mjs  # Astro configuration
├── package.json     # Dependencies and scripts
└── tsconfig.json     # TypeScript config
```

## Available Scripts
| Command | Description |
|---------|-------------|
| `bun dev` | Start development server |
| `bun build` | Build for production |
| `bun preview` | Preview production build |

## Dependencies
- `astro`: ^5.0.0
- `typescript`: ^5.0.0 (dev)

## Key Conventions
1. Components go in `src/components/`
2. Layouts go in `src/layouts/`
3. Pages go in `src/pages/`
4. Use `bun run build` to verify the project compiles

## Development Workflow
1. Make changes to components/pages
2. Run `bun dev` to test locally
3. Run `bun build` to verify build passes
4. Commit changes
