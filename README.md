# Disordered.ru
`npm i` - Update dependencies

## Development
`npm run dev`

## Production
`npm run build` - Build with Webpack

### post-recieve git hook
`nano .git/hooks/post-recieve`

```
#!/bin/bash
cd ../..
npm i
npm run build
```

`chmod +x .git/hooks/post-recieve`
